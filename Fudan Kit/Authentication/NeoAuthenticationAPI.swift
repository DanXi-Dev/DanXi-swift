import Foundation
import SwiftSoup
import SwiftyRSA
import SwiftyJSON
import Utils

public enum NeoAuthenticationAPI {
    private static let idURL = URL(string: "https://id.fudan.edu.cn")!
    private static let credentialCheckURL = URL(string: "https://id.fudan.edu.cn/api-uc/oauth2/authorization/bam")!

    /// Check if the user's credential is correct without relying on an external
    /// business service (for example, ecard).
    ///
    /// A temporary session is used so an existing ID cookie cannot make an
    /// incorrect username/password pair appear valid.
    /// - Returns: `true` if the credential is accepted, `false` otherwise.
    public static func checkUserCredential(username: String, password: String) async throws -> Bool {
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }

        let firstRequest = constructRequest(credentialCheckURL)
        let (firstData, firstResponse) = try await data(for: firstRequest, session: session)

        guard let redirectedURL = firstResponse.url,
              redirectedURL.host() == idURL.host() else {
            throw LocatableError()
        }

        // An ephemeral session should always reach the login page. If the ID
        // server unexpectedly returns an authentication result directly, finish
        // that flow but do not treat it as validation of the supplied credential.
        if let document = try? decodeHTMLDocument(firstData),
           let authenticationRequest = try? constructAuthenticationResultRequest(document: document) {
            _ = try await data(for: authenticationRequest, session: session)
            return false
        }

        let parameters = try await getParams(url: redirectedURL, session: session)
        let publicKey = try await getPublicKey(session: session)
        guard let token = try await encryptAndSubmit(
            publicKey: publicKey,
            parameters: parameters,
            username: username,
            password: password,
            session: session
        ) else {
            return false
        }

        // Finish the ID flow as well as checking authExecute's result. This
        // ensures a successful result represents a complete ID login rather
        // than only a successful password-encryption request.
        let document = try await postJWToken(token: token, session: session)
        let authenticationRequest = try constructAuthenticationResultRequest(document: document)
        let (_, response) = try await data(for: authenticationRequest, session: session)

        guard let responseURL = response.url,
              responseURL.host() == idURL.host(),
              !responseURL.path.hasPrefix("/idp/"),
              !responseURL.path.hasPrefix("/ac/") else {
            return false
        }
        return true
    }

    public static func authenticate(_ url: URL) async throws -> (Data, URLResponse) {
        let firstRequest = constructRequest(url)
        let (firstData, firstResponse) = try await data(for: firstRequest)
        
        // already authenticated, no further action required
        if firstResponse.url?.host() == url.host() {
            return (firstData, firstResponse)
        }
        
        guard let redirectedURL = firstResponse.url,
              redirectedURL.host() == "id.fudan.edu.cn" else {
            throw LocatableError()
        }
        
        // check if is already authenticated, and an authentication result is returned
        if let document = try? decodeHTMLDocument(firstData),
           let authenticationRequest = try? constructAuthenticationResultRequest(document: document) {
            return try await data(for: authenticationRequest)
        }
        
        // full authentication process
        let parameters = try await getParams(url: redirectedURL)
        let publicKey = try await getPublicKey()
        guard let username = CredentialStore.shared.username,
              let password = CredentialStore.shared.password else {
            throw CampusError.credentialNotFound
        }
        guard let token = try await encryptAndSubmit(
            publicKey: publicKey,
            parameters: parameters,
            username: username,
            password: password
        ) else {
            throw CampusError.loginFailed
        }
        let document = try await postJWToken(token: token)
        let authenticationRequest = try constructAuthenticationResultRequest(document: document)
        let (data, response) = try await data(for: authenticationRequest)
        return (data, response)
    }

    private static func getParams(url: URL, session: URLSession? = nil) async throws -> Parameters {
        // parse URL to get `lck` and `entityId` locally
        let urlString = url.absoluteString
        guard let hashRange = urlString.range(of: "#") else {
            throw LocatableError()
        }
        let hashPart = String(urlString[hashRange.upperBound...])
        
        guard let components = URLComponents(string: idURL.absoluteString + hashPart),
              let queryItems = components.queryItems else {
            throw LocatableError()
        }
        
        guard let lck = queryItems.first(where: { $0.name == "lck" })?.value,
              let entityId = queryItems.first(where: { $0.name == "entityId" })?.value else {
            throw LocatableError()
        }
        
        // retrieve `authChainCode` from server
        let authMethodsURL = idURL.appendingPathComponent("/idp/authn/queryAuthMethods")
        let request = try constructJSONRequest(authMethodsURL, payload: ["lck": lck, "entityId": entityId])
        let (data, _) = try await data(for: request, session: session)
        
        let responseJSON = try JSON(data: data)
        guard let authMethodsList = responseJSON["data"].array,
              let passwordJSON = authMethodsList.first(where: { $0["moduleCode"] == "userAndPwd" }),
              let authChainCode = passwordJSON["authChainCode"].string else {
            throw LocatableError()
        }
        
        return Parameters(lck: lck, entityId: entityId, chainCode: authChainCode)
    }

    private static func getPublicKey(session: URLSession? = nil) async throws -> PublicKey {
        let url = idURL.appendingPathComponent("/idp/authn/getJsPublicKey")
        let request = constructRequest(url, method: "POST")
        let (data, _) = try await data(for: request, session: session)
        let json = try JSON(data: data)
        guard let encodedKey = json["data"].string else {
            throw LocatableError()
        }
        return try PublicKey(base64Encoded: encodedKey)
    }

    private static func encryptAndSubmit(
        publicKey: PublicKey,
        parameters: Parameters,
        username: String,
        password: String,
        session: URLSession? = nil
    ) async throws -> String? {
        let plaintext = try ClearMessage(string: password, using: String.Encoding.utf8)
        let cipher = try plaintext.encrypted(with: publicKey, padding: .PKCS1)
        let encryptedPassword = cipher.data.base64EncodedString()
        
        let payload: [String: Any] = [
            "authModuleCode": "userAndPwd",
            "authChainCode": parameters.chainCode,
            "entityId": parameters.entityId,
            "requestType": "chain_type",
            "lck": parameters.lck,
            "authPara": [
                "loginName": username,
                "password": encryptedPassword,
                "verifyCode": ""
            ]
        ]
        
        let authenticateURL = idURL.appendingPathComponent("/idp/authn/authExecute")
        let request = try constructJSONRequest(authenticateURL, payload: payload)
        let (data, _) = try await data(for: request, session: session)
        let responseJSON = try JSON(data: data)
        
        guard let responseCode = responseJSON["code"].int,
              responseCode == 200 else {
            return nil
        }
        
        guard let token = responseJSON["loginToken"].string else {
            throw LocatableError()
        }
        return token
    }
    
    private static func postJWToken(token: String, session: URLSession? = nil) async throws -> Document {
        let loginURL = idURL.appendingPathComponent("/idp/authCenter/authnEngine")
        let request = constructFormRequest(loginURL, form: ["loginToken": token])
        let (data, _) = try await data(for: request, session: session)
        
        let document = try decodeHTMLDocument(data)
        return document
    }
    
    /// Construct the request represented by ID's auto-submit result form.
    ///
    /// CAS-style services usually return a GET form containing `ticket`, while
    /// the ID user center uses an OIDC POST form containing fields such as
    /// `code` and `state`. Submitting the form as returned supports both flows.
    private static func constructAuthenticationResultRequest(document: Document) throws -> URLRequest {
        guard let form = try document.getElementById("logon"),
              let submitURL = URL(string: try form.attr("action"), relativeTo: idURL)?.absoluteURL else {
            throw LocatableError()
        }

        var fields: [String: String] = [:]
        for input in try form.select("input[name]") {
            let name = try input.attr("name")
            guard !name.isEmpty else { continue }
            fields[name] = try input.attr("value")
        }

        guard !fields.isEmpty else {
            throw LocatableError()
        }

        if try form.attr("method").caseInsensitiveCompare("post") == .orderedSame {
            var request = constructRequest(submitURL, method: "POST")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            var bodyComponents = URLComponents()
            bodyComponents.queryItems = fields.map { URLQueryItem(name: $0.key, value: $0.value) }
            guard let body = bodyComponents.percentEncodedQuery?.data(using: .utf8) else {
                throw LocatableError()
            }
            request.httpBody = body
            return request
        }

        guard var components = URLComponents(url: submitURL, resolvingAgainstBaseURL: false) else {
            throw LocatableError()
        }
        let existingQueryItems = components.queryItems ?? []
        components.queryItems = existingQueryItems + fields.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = components.url else { throw LocatableError() }
        return constructRequest(url)
    }

    private static func data(for request: URLRequest, session: URLSession? = nil) async throws -> (Data, URLResponse) {
        if let session {
            return try await session.data(for: request)
        }
        return try await URLSession.campusSession.data(for: request)
    }

    private static func data(from url: URL, session: URLSession? = nil) async throws -> (Data, URLResponse) {
        if let session {
            return try await session.data(from: url)
        }
        return try await URLSession.campusSession.data(from: url)
    }
}

private struct Parameters {
    let lck: String
    let entityId: String
    let chainCode: String
}
