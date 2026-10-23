import Foundation
import SwiftSoup
import SwiftyRSA
import SwiftyJSON
import Utils

public enum AuthenticationAPI {
    private static let idURL = URL(string: "https://id.fudan.edu.cn")!
    private static let credentialCheckURL = URL(string: "https://id.fudan.edu.cn/api-uc/oauth2/authorization/bam")!

    /// Keep the image and its authentication chain together until submission.
    public final class CaptchaChallenge {
        public let imageData: Data
        fileprivate let parameters: Parameters
        public let username: String
        fileprivate let session: URLSession?
        fileprivate let credentialCheck: Bool

        fileprivate init(imageData: Data, parameters: Parameters, username: String, session: URLSession?, credentialCheck: Bool) {
            self.imageData = imageData
            self.parameters = parameters
            self.username = username
            self.session = session
            self.credentialCheck = credentialCheck
        }

        deinit { if credentialCheck { session?.invalidateAndCancel() } }
    }

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
        if try await getCaptcha(parameters: parameters, username: username, session: session) != nil {
            throw CampusError.needCaptcha
        }
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

    /// Request a captcha using the temporary credential-check session.
    public static func requestCredentialCheckCaptcha(username: String) async throws -> CaptchaChallenge? {
        let session = URLSession(configuration: .ephemeral)
        var retainedByChallenge = false
        defer { if !retainedByChallenge { session.invalidateAndCancel() } }

        let request = constructRequest(credentialCheckURL)
        let (firstData, response) = try await data(for: request, session: session)
        guard let redirectedURL = response.url,
              redirectedURL.host() == idURL.host() else { throw LocatableError() }
        if let document = try? decodeHTMLDocument(firstData),
           let authenticationRequest = try? constructAuthenticationResultRequest(document: document) {
            _ = try await data(for: authenticationRequest, session: session)
            return nil
        }
        let parameters = try await getParams(url: redirectedURL, session: session)
        guard let imageData = try await getCaptcha(parameters: parameters, username: username, session: session) else {
            return nil
        }
        retainedByChallenge = true
        return CaptchaChallenge(imageData: imageData, parameters: parameters, username: username, session: session, credentialCheck: true)
    }

    /// Submit the answer in the session that produced the image.
    public static func checkUserCredential(password: String, challenge: CaptchaChallenge, verifyCode: String) async throws -> Bool {
        guard challenge.credentialCheck, !verifyCode.isEmpty else { throw LocatableError() }
        let publicKey = try await getPublicKey(session: challenge.session)
        guard let token = try await encryptAndSubmit(
            publicKey: publicKey,
            parameters: challenge.parameters,
            username: challenge.username,
            password: password,
            verifyCode: verifyCode,
            session: challenge.session
        ) else { return false }
        let document = try await postJWToken(token: token, session: challenge.session)
        let authenticationRequest = try constructAuthenticationResultRequest(document: document)
        let (_, response) = try await data(for: authenticationRequest, session: challenge.session)
        guard let responseURL = response.url,
              responseURL.host() == idURL.host(),
              !responseURL.path.hasPrefix("/idp/"),
              !responseURL.path.hasPrefix("/ac/") else { return false }
        return true
    }

    public static func authenticate(_ url: URL, session: URLSession? = nil) async throws -> (Data, URLResponse) {
        let firstRequest = constructRequest(url)
        let (firstData, firstResponse) = try await data(for: firstRequest, session: session)

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
            return try await data(for: authenticationRequest, session: session)
        }

        // full authentication process
        let parameters = try await getParams(url: redirectedURL, session: session)
        guard let credential = CredentialStore.shared.credentials(for: url) else {
            throw CampusError.credentialNotFound
        }
        if try await getCaptcha(parameters: parameters, username: credential.username, session: session) != nil {
            throw CampusError.needCaptcha
        }
        let publicKey = try await getPublicKey(session: session)
        guard let token = try await encryptAndSubmit(
            publicKey: publicKey,
            parameters: parameters,
            username: credential.username,
            password: credential.password,
            session: session
        ) else {
            throw CampusError.loginFailed
        }
        let document = try await postJWToken(token: token, session: session)
        let authenticationRequest = try constructAuthenticationResultRequest(document: document)
        let (data, response) = try await data(for: authenticationRequest, session: session)
        return (data, response)
    }

    /// Prepare a captcha for SSO using the session for the target service.
    public static func requestCaptcha(for url: URL, username: String, session: URLSession? = nil) async throws -> CaptchaChallenge? {
        let request = constructRequest(url)
        let (firstData, response) = try await data(for: request, session: session)
        if response.url?.host() == url.host() { return nil }
        if let document = try? decodeHTMLDocument(firstData),
           let authenticationRequest = try? constructAuthenticationResultRequest(document: document) {
            _ = try await data(for: authenticationRequest, session: session)
            return nil
        }
        guard let redirectedURL = response.url,
              redirectedURL.host() == idURL.host() else { throw LocatableError() }
        let parameters = try await getParams(url: redirectedURL, session: session)
        guard let imageData = try await getCaptcha(parameters: parameters, username: username, session: session) else { return nil }
        return CaptchaChallenge(imageData: imageData, parameters: parameters, username: username, session: session, credentialCheck: false)
    }

    public static func authenticate(_ challenge: CaptchaChallenge, password: String, verifyCode: String) async throws -> (Data, URLResponse) {
        guard !challenge.credentialCheck, !verifyCode.isEmpty else { throw LocatableError() }
        let publicKey = try await getPublicKey(session: challenge.session)
        guard let token = try await encryptAndSubmit(
            publicKey: publicKey,
            parameters: challenge.parameters,
            username: challenge.username,
            password: password,
            verifyCode: verifyCode,
            session: challenge.session
        ) else { throw CampusError.loginFailed }
        let document = try await postJWToken(token: token, session: challenge.session)
        let authenticationRequest = try constructAuthenticationResultRequest(document: document)
        return try await data(for: authenticationRequest, session: challenge.session)
    }

    /// Authenticate and return the callback URL without consuming its ticket.
    ///
    /// This is intended for components such as `SFSafariViewController` that
    /// need to establish their own authenticated session from a URL.
    public static func authenticateForURL(_ url: URL) async throws -> URL {
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }
        return try await authenticateForURL(url, session: session)
    }

    /// Return ID's callback without consuming its ticket. The caller owns the
    /// session and can use it to finish any service-specific authentication hops.
    public static func authenticateForURL(_ url: URL, session: URLSession) async throws -> URL {
        let firstRequest = constructRequest(url)
        let (firstData, firstResponse) = try await data(for: firstRequest, session: session)

        if firstResponse.url?.host() == url.host() {
            guard let responseURL = firstResponse.url else {
                throw LocatableError()
            }
            return responseURL
        }

        guard let redirectedURL = firstResponse.url,
              redirectedURL.host() == idURL.host() else {
            throw LocatableError()
        }

        let authenticationRequest: URLRequest
        if let document = try? decodeHTMLDocument(firstData),
           let existingRequest = try? constructAuthenticationResultRequest(document: document) {
            authenticationRequest = existingRequest
        } else {
            let parameters = try await getParams(url: redirectedURL, session: session)
            guard let credential = CredentialStore.shared.credentials(for: url) else {
                throw CampusError.credentialNotFound
            }
            if try await getCaptcha(parameters: parameters, username: credential.username, session: session) != nil {
                throw CampusError.needCaptcha
            }
            let publicKey = try await getPublicKey(session: session)
            guard let token = try await encryptAndSubmit(
                publicKey: publicKey,
                parameters: parameters,
                username: credential.username,
                password: credential.password,
                session: session
            ) else {
                throw CampusError.loginFailed
            }
            let document = try await postJWToken(token: token, session: session)
            authenticationRequest = try constructAuthenticationResultRequest(document: document)
        }

        guard authenticationRequest.httpMethod == "GET",
              let authenticationURL = authenticationRequest.url else {
            throw LocatableError()
        }
        return authenticationURL
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

    private static func getCaptcha(parameters: Parameters, username: String, session: URLSession? = nil) async throws -> Data? {
        let url = idURL.appendingPathComponent("/idp/authn/verifyCodeIsNeed")
        let payload: [String: Any] = [
            "lang": NSNull(),
            "loginName": username,
            "chainCode": parameters.chainCode,
            "authModuleCode": "userAndPwd"
        ]
        let request = try constructJSONRequest(url, payload: payload)
        let (responseData, _) = try await data(for: request, session: session)
        let json = try JSON(data: responseData)
        guard let isNeeded = json["result"].bool else { throw LocatableError() }
        guard isNeeded else { return nil }
        guard let image = json["pic"].string,
              let separator = image.firstIndex(of: ","),
              image[..<separator].hasPrefix("data:image/"),
              let imageData = Data(base64Encoded: String(image[image.index(after: separator)...])),
              !imageData.isEmpty else { throw LocatableError() }
        return imageData
    }

    private static func encryptAndSubmit(
        publicKey: PublicKey,
        parameters: Parameters,
        username: String,
        password: String,
        verifyCode: String = "",
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
                "verifyCode": verifyCode
            ]
        ]

        let authenticateURL = idURL.appendingPathComponent("/idp/authn/authExecute")
        let request = try constructJSONRequest(authenticateURL, payload: payload)
        let (data, _) = try await data(for: request, session: session)
        let responseJSON = try JSON(data: data)

        guard let responseCode = responseJSON["code"].int else { throw LocatableError() }
        if responseCode == 4333 && verifyCode.isEmpty && !username.isEmpty {
            throw CampusError.needCaptcha
        }
        guard responseCode == 200 else { return nil }

        guard let token = responseJSON["loginToken"].string else {
            throw LocatableError()
        }
        return token
    }

    private static func postJWToken(token: String, session: URLSession? = nil) async throws -> Document {
        let loginURL = idURL.appendingPathComponent("/idp/authCenter/authnEngine")
        var request = constructRequest(loginURL, method: "POST")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        // URLComponents encodes the form value once; constructFormRequest pre-encodes it again.
        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [URLQueryItem(name: "loginToken", value: token)]
        guard let body = bodyComponents.percentEncodedQuery?.data(using: .utf8) else {
            throw LocatableError()
        }
        request.httpBody = body
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

fileprivate struct Parameters {
    let lck: String
    let entityId: String
    let chainCode: String
}
