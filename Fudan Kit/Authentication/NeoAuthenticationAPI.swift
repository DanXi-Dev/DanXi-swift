import Foundation
import SwiftSoup
import SwiftyRSA
import SwiftyJSON
import Utils

public enum NeoAuthenticationAPI {
    private static let idURL = URL(string: "https://id.fudan.edu.cn")!
    
    public static func authenticate(_ url: URL) async throws -> (Data, URLResponse) {
        let firstRequest = constructRequest(url)
        let (firstData, firstResponse) = try await URLSession.campusSession.data(for: firstRequest)
        
        // already authenticated, no further action required
        if firstResponse.url?.host() == url.host() {
            return (firstData, firstResponse)
        }
        
        guard let redirectedURL = firstResponse.url,
              redirectedURL.host() == "id.fudan.edu.cn" else {
            throw LocatableError()
        }
        
        // check if is already authenticated, and ticket is returned
        if let document = try? decodeHTMLDocument(firstData),
           let authenticationURL = try? retrieveRedirectURL(document: document) {
            return try await URLSession.campusSession.data(from: authenticationURL)
        }
        
        // full authentication process
        let parameters = try await getParams(url: redirectedURL)
        let publicKey = try await getPublicKey()
        let token = try await encryptAndSubmit(publicKey: publicKey, parameters: parameters)
        let document = try await postJWToken(token: token)
        let authenticationURL = try retrieveRedirectURL(document: document)
        let (data, response) = try await URLSession.campusSession.data(from: authenticationURL)
        return (data, response)
    }
    
    private static func getParams(url: URL) async throws -> Parameters {
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
        let (data, _) = try await URLSession.campusSession.data(for: request)
        
        let responseJSON = try JSON(data: data)
        guard let authMethodsList = responseJSON["data"].array,
              let passwordJSON = authMethodsList.first(where: { $0["moduleCode"] == "userAndPwd" }),
              let authChainCode = passwordJSON["authChainCode"].string else {
            throw LocatableError()
        }
        
        return Parameters(lck: lck, entityId: entityId, chainCode: authChainCode)
    }
    
    private static func getPublicKey() async throws -> PublicKey {
        let url = idURL.appendingPathComponent("/idp/authn/getJsPublicKey")
        let request = constructRequest(url, method: "POST")
        let (data, _) = try await URLSession.campusSession.data(for: request)
        let json = try JSON(data: data)
        guard let encodedKey = json["data"].string else {
            throw LocatableError()
        }
        return try PublicKey(base64Encoded: encodedKey)
    }
    
    private static func encryptAndSubmit(publicKey: PublicKey, parameters: Parameters) async throws -> String {
        guard let username = CredentialStore.shared.username,
              let password = CredentialStore.shared.password else {
            throw CampusError.credentialNotFound
        }
        
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
        let (data, _) = try await URLSession.campusSession.data(for: request)
        let responseJSON = try JSON(data: data)
        
        guard let responseCode = responseJSON["code"].int,
              responseCode == 200 else {
            throw CampusError.loginFailed
        }
        
        guard let token = responseJSON["loginToken"].string else {
            throw LocatableError()
        }
        return token
    }
    
    private static func postJWToken(token: String) async throws -> Document {
        let loginURL = idURL.appendingPathComponent("/idp/authCenter/authnEngine")
        let request = constructFormRequest(loginURL, form: ["loginToken": token])
        let (data, _) = try await URLSession.campusSession.data(for: request)
        
        let document = try decodeHTMLDocument(data)
        return document
    }
    
    private static func retrieveRedirectURL(document: Document) throws -> URL {
        guard let form = try document.getElementById("logon"),
              let submitURL = URL(string: try form.attr("action"))
               else {
            throw LocatableError()
        }
        
        guard let inputElement = try document.getElementById("ticket") else {
            throw LocatableError()
        }
        let ticket = try inputElement.attr("value")
        
        guard var components = URLComponents(url: submitURL, resolvingAgainstBaseURL: false) else {
            throw LocatableError()
        }
        let ticketQuery = URLQueryItem(name: "ticket", value: ticket)
        
        if components.queryItems == nil {
            components.queryItems = [ticketQuery]
        } else {
            components.queryItems?.append(ticketQuery)
        }
        
        guard let redirectURL = components.url else {
            throw LocatableError()
        }
        
        return redirectURL
    }
}

private struct Parameters {
    let lck: String
    let entityId: String
    let chainCode: String
}
