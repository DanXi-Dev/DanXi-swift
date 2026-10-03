import Foundation
import SwiftSoup

/// Reader account, circulation and request APIs captured from the Fudan OPAC.
public enum LibraryAccountAPI {
    private static let baseURL = URL(string: "https://fdulspgw.fudan.edu.cn/alsp/open-api")!

    public static func getReaderInfo() async throws -> LibraryReaderInfo {
        try await get("/elib5/getReaderInfo")
    }

    public static func getCurrentLoans(page: Int = 1, pageSize: Int = 10) async throws -> LibraryAccountPage<LibraryCurrentLoan> {
        try await get("/elib5/getReaderCurrentLoan", query: [
            URLQueryItem(name: "pageSize", value: String(pageSize)),
            URLQueryItem(name: "pageNo", value: String(page))
        ])
    }

    public static func renewLoan(_ loan: LibraryCurrentLoan) async throws {
        let reader = try await getReaderInfo()
        let _: LibraryEmptyData = try await post("/elib5/renewLoan", body: RenewLoanRequest(
            itemBarcode: loan.itemBarcode,
            userBarcode: reader.barcode
        ))
    }

    public static func getLoanHistory(page: Int = 1, pageSize: Int = 10) async throws -> LibraryAccountPage<LibraryLoanHistoryItem> {
        try await get("/elib5/v2/getReaderHistoryLoan", query: [
            URLQueryItem(name: "pageSize", value: String(pageSize)),
            URLQueryItem(name: "pageNo", value: String(page))
        ])
    }

    public static func getRequests(
        range: LibraryRequestRange,
        page: Int = 1,
        pageSize: Int = 10
    ) async throws -> LibraryAccountPage<LibraryBookRequest> {
        try await post("/elib5/searchReaderRequest", body: SearchRequestsRequest(
            range: range.rawValue,
            pageSize: pageSize,
            pageNo: page
        ))
    }

    public static func cancelRequest(id: Int) async throws {
        let _: LibraryEmptyData = try await post("/elib5/cancelRequest", body: CancelRequest(requestId: id))
    }

    public static func getRequestPolicy(itemBarcode: String) async throws -> LibraryRequestPolicy {
        try await post("/elib5/selectRequestDays", body: ItemBarcodeRequest(itemBarcode: itemBarcode))
    }

    public static func getPickupLocations(libraryCode: String, locationCode: String) async throws -> LibraryPickupLocations {
        try await get("/system/location/canPickupSimpleList", query: [
            URLQueryItem(name: "libraryCode", value: libraryCode),
            URLQueryItem(name: "locationCode", value: locationCode)
        ])
    }

    /// `expectDate` must be formatted as yyyy-MM-dd and fall within the policy's date range.
    public static func addRequest(
        itemBarcode: String,
        expectDate: String,
        pickupLocation: LibraryPickupLocation,
        allowReplace: Bool
    ) async throws -> LibraryRequestResult {
        try await post("/elib5/addRequest", body: AddRequest(
            itemBarcode: itemBarcode,
            expectDate: expectDate,
            pickupLocation: pickupLocation.code,
            allowReplace: allowReplace ? "1" : "0"
        ))
    }

    private static func get<Value: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> Value {
        var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false)!
        components.queryItems = query.isEmpty ? nil : query
        let request = constructRequest(components.url!)
        return try await perform(request)
    }

    private static func post<Body: Encodable, Value: Decodable>(_ path: String, body: Body) async throws -> Value {
        let payload = try JSONEncoder().encode(body)
        var request = constructRequest(baseURL.appending(path: path), payload: payload)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await perform(request)
    }

    private static func perform<Value: Decodable>(_ request: URLRequest) async throws -> Value {
        let data = try await LibraryAccountSession.shared.data(for: request)
        let envelope = try JSONDecoder().decode(LibraryAccountEnvelope<Value>.self, from: data)
        guard envelope.code == 200, let value = envelope.data else {
            throw CampusError.customError(message: envelope.errorMessage)
        }
        return value
    }
}

private struct LibraryAccountEnvelope<Value: Decodable>: Decodable {
    let code: Int
    let data: Value?
    let msg: String?
    let message: String?

    private enum CodingKeys: String, CodingKey { case code, data, msg, message }

    var errorMessage: String { message ?? msg ?? "图书馆请求失败" }
}

private struct LibraryEmptyData: Decodable {}

private struct RenewLoanRequest: Encodable {
    let itemBarcode: String
    let userBarcode: String
}

private struct SearchRequestsRequest: Encodable {
    let range: Int
    let pageSize: Int
    let pageNo: Int
}

private struct CancelRequest: Encodable { let requestId: Int }
private struct ItemBarcodeRequest: Encodable { let itemBarcode: String }

private struct AddRequest: Encodable {
    let itemBarcode: String
    let expectDate: String
    let pickupLocation: String
    let allowReplace: String
}

/// The OPAC OAuth token is held in memory and renewed through the captured SSO flow.
private actor LibraryAccountSession {
    static let shared = LibraryAccountSession()

    private let authURL = URL(string: "https://fdulib.a-lsp.com")!
    private let gatewayURL = URL(string: "https://fdulspgw.fudan.edu.cn")!
    private let clientID = "rfid"
    private let tenantID = "fdulib"
    private let redirectURI = "https://opac.fudan.edu.cn/#/redirect"
    private var token: String?
    private var tokenExpiry = Date.distantPast
    private var tokenUsername: String?
    func data(for originalRequest: URLRequest) async throws -> Data {
        var request = originalRequest
        request.setValue(try await accessToken(), forHTTPHeaderField: "access_token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        var (data, _) = try await URLSession.campusSession.data(for: request)

        // The gateway reports an expired token as a JSON business error.
        if let status = try? JSONDecoder().decode(LibraryStatus.self, from: data),
           status.code == 401 || status.code == 403 {
            token = nil
            request.setValue(try await accessToken(), forHTTPHeaderField: "access_token")
            (data, _) = try await URLSession.campusSession.data(for: request)
        }
        return data
    }

    private func accessToken() async throws -> String {
        guard let username = CredentialStore.shared.username else {
            throw CampusError.credentialNotFound
        }
        if tokenUsername == username, let token, tokenExpiry > Date().addingTimeInterval(60) {
            return token
        }
        token = nil
        tokenUsername = username
        return try await login()
    }

    private func login() async throws -> String {
        let parameters = [
            URLQueryItem(name: "target", value: "true"),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "loginType", value: "member"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI)
        ]

        // The first page establishes the same cookie context as the web OPAC.
        var authPageComponents = URLComponents(url: authURL.appendingPathComponent("authServer", isDirectory: true), resolvingAgainstBaseURL: false)!
        authPageComponents.queryItems = parameters
        let authPage = authPageComponents.url!
        var authPageRequest = constructRequest(authPage)
        authPageRequest.setValue("https://opac.fudan.edu.cn/", forHTTPHeaderField: "Referer")
        _ = try await URLSession.campusSession.data(for: authPageRequest)

        let payload = [
            "target": "true", "response_type": "code", "loginType": "member",
            "client_id": clientID, "redirect_uri": redirectURI
        ]
        var clientRequest = constructRequest(authURL.appending(path: "/open-api/openapi/oauth2/getClientParams"),
                                             payload: try JSONEncoder().encode(payload))
        clientRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        clientRequest.setValue(tenantID, forHTTPHeaderField: "tenant-id")
        clientRequest.setValue("https://fdulib.a-lsp.com", forHTTPHeaderField: "Origin")
        clientRequest.setValue(authPage.absoluteString, forHTTPHeaderField: "Referer")
        let clientData = try await URLSession.campusSession.data(for: clientRequest).0
        let client = try decode(String.self, from: clientData)
        guard let loginURL = URL(string: client) else { throw CampusError.loginFailed }

        let (loginPage, loginResponse) = try await NeoAuthenticationAPI.authenticate(loginURL)

        let callbackURL: URL
        if let finalURL = loginResponse.url, finalURL.path == "/authServer/auth" {
            callbackURL = finalURL
        } else {
            callbackURL = try await submitCASForm(loginPage, responseURL: loginResponse.url)
        }

        guard let callbackComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              callbackComponents.path == "/authServer/auth",
              let query = callbackComponents.queryItems,
              query.contains(where: { $0.name == "authCode" }),
              query.contains(where: { $0.name == "ticket" }) else {
            throw CampusError.loginFailed
        }
        let callback = url(host: authURL, path: "/open-api/openapi/oauth2/authCallBack", query: query)
        var callbackRequest = constructRequest(callback)
        callbackRequest.setValue(tenantID, forHTTPHeaderField: "tenant-id")
        callbackRequest.setValue(callbackURL.absoluteString, forHTTPHeaderField: "Referer")
        let callbackData = try await URLSession.campusSession.data(for: callbackRequest).0
        let callbackResult: LibraryCallback = try decode(LibraryCallback.self, from: callbackData)
        guard !callbackResult.openToken.isEmpty else { throw CampusError.loginFailed }

        let authorize = url(host: authURL, path: "/open-api/openapi/oauth2/authorize", query: parameters)
        var authorizeRequest = constructRequest(authorize)
        authorizeRequest.setValue(tenantID, forHTTPHeaderField: "tenant-id")
        authorizeRequest.setValue(callbackResult.openToken, forHTTPHeaderField: "openToken")
        authorizeRequest.setValue(callbackURL.absoluteString, forHTTPHeaderField: "Referer")
        let firstData = try await URLSession.campusSession.data(for: authorizeRequest).0
        let first: LibraryAuthorization = try decode(LibraryAuthorization.self, from: firstData)
        if first.redirectUri == nil {
            let confirm = url(host: authURL, path: "/open-api/openapi/oauth2/doConfirm", query: parameters)
            var confirmRequest = constructRequest(confirm)
            confirmRequest.setValue(tenantID, forHTTPHeaderField: "tenant-id")
            confirmRequest.setValue(callbackResult.openToken, forHTTPHeaderField: "openToken")
            confirmRequest.setValue(callbackURL.absoluteString, forHTTPHeaderField: "Referer")
            let confirmedData = try await URLSession.campusSession.data(for: confirmRequest).0
            try checkStatus(confirmedData)
        }
        let authorization: LibraryAuthorization
        if first.redirectUri == nil {
            let authorizedData = try await URLSession.campusSession.data(for: authorizeRequest).0
            authorization = try decode(LibraryAuthorization.self, from: authorizedData)
        } else {
            authorization = first
        }
        guard let redirect = authorization.redirectUri,
              let fragment = URLComponents(string: redirect)?.fragment,
              let queryPart = fragment.split(separator: "?", maxSplits: 1).last,
              let code = URLComponents(string: "https://opac.fudan.edu.cn/?\(queryPart)")?
                .queryItems?.first(where: { $0.name == "code" })?.value else {
            throw CampusError.loginFailed
        }

        let tokenURL = url(host: gatewayURL, path: "/alsp/open-api/openapi/oauth2/getToken", query: [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ])
        var tokenRequest = constructRequest(tokenURL)
        tokenRequest.setValue("https://opac.fudan.edu.cn", forHTTPHeaderField: "Origin")
        tokenRequest.setValue("https://opac.fudan.edu.cn/", forHTTPHeaderField: "Referer")
        let tokenData = try await URLSession.campusSession.data(for: tokenRequest).0
        let result: LibraryToken = try decode(LibraryToken.self, from: tokenData)
        token = result.accessToken
        tokenExpiry = Date().addingTimeInterval(TimeInterval(result.expiresIn))
        return result.accessToken
    }

    private func submitCASForm(_ html: Data, responseURL: URL?) async throws -> URL {
        guard let responseURL, responseURL.host == "rwsjcas.fudan.edu.cn",
              let text = String(data: html, encoding: .utf8) else {
            throw CampusError.loginFailed
        }
        let document = try SwiftSoup.parse(text)
        guard let form = try document.getElementById("fm1"),
              let action = URL(string: try form.attr("action"), relativeTo: responseURL)?.absoluteURL else {
            throw CampusError.loginFailed
        }
        var fields: [String: String] = [:]
        for input in try form.select("input[name]") {
            fields[try input.attr("name")] = try input.attr("value")
        }
        let actionItems = URLComponents(url: action, resolvingAgainstBaseURL: false)?.queryItems ?? []
        guard actionItems.contains(where: { $0.name == "username" }),
              actionItems.contains(where: { $0.name == "password" }) else {
            throw CampusError.loginFailed
        }
        for key in ["username", "password", "domainName", "source"] {
            if let value = actionItems.first(where: { $0.name == key })?.value { fields[key] = value }
        }
        // This is the hidden verification field submitted by the OPAC's CAS page.
        if fields["imgverifycode"] != nil { fields["imgverifycode"] = "******" }
        let formBody = fields.map { field in
            let name = field.key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
            let value = field.value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
            return "\(name)=\(value)"
        }.joined(separator: "&")
        var request = constructRequest(action, method: "POST")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("https://rwsjcas.fudan.edu.cn", forHTTPHeaderField: "Origin")
        request.setValue(responseURL.absoluteString, forHTTPHeaderField: "Referer")
        request.httpBody = formBody.data(using: .utf8)
        let (_, response) = try await URLSession.campusSession.data(for: request)
        guard let callback = response.url else { throw CampusError.loginFailed }
        return callback
    }

    private func url(host: URL, path: String, query: [URLQueryItem]) -> URL {
        var components = URLComponents(url: host.appending(path: path), resolvingAgainstBaseURL: false)!
        components.queryItems = query
        return components.url!
    }

    private func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {
        let envelope = try JSONDecoder().decode(LibraryAccountEnvelope<Value>.self, from: data)
        guard envelope.code == 200, let value = envelope.data else {
            throw CampusError.customError(message: envelope.errorMessage)
        }
        return value
    }

    private func checkStatus(_ data: Data) throws {
        let status = try JSONDecoder().decode(LibraryStatus.self, from: data)
        guard status.code == 200 else {
            throw CampusError.customError(message: status.msg ?? "图书馆授权失败")
        }
    }
}

private struct LibraryStatus: Decodable {
    let code: Int
    let msg: String?
}

private struct LibraryCallback: Decodable {
    let openToken: String
}

private struct LibraryAuthorization: Decodable {
    let redirectUri: String?
}

private struct LibraryToken: Decodable {
    let accessToken: String
    let expiresIn: Int

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
    }
}
