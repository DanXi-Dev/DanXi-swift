import Foundation

public var authURL = constructBaseURL(key: "fduhole_auth_url", defaultURL: "https://auth.fduhole.com/api")
public var forumURL = constructBaseURL(key: "fduhole_base_url", defaultURL: "https://www.fduhole.com/api")
public var curriculumURL = constructBaseURL(key: "danke_base_url", defaultURL: "https://danke.fduhole.com/api")

private func constructBaseURL(key: String, defaultURL: String) -> URL {
    if let stored = UserDefaults.standard.string(forKey: key) {
        URL(string: stored)!
    } else {
        URL(string: defaultURL)!
    }
}

func requestWithData(_ path: String, base: URL, protected: Bool = true, params: [String: String]? = nil, payload: [String: Any]? = nil, method: String? = nil) async throws -> Data {
    var url = base.appendingPathComponent(path)
    if let params {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        url = components.url!
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = method ?? (payload == nil ? "GET" : "POST")
    if let payload {
        let data = try JSONSerialization.data(withJSONObject: payload)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
    }
    
    let (data, response) = if protected {
        try await Authenticator.shared.authenticate(request: request)
    } else {
        try await URLSession.shared.data(for: request)
    }
    
    guard let httpResponse = response as? HTTPURLResponse else {
        throw URLError(.badServerResponse)
    }
    
    if httpResponse.statusCode >= 300 {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String {
            throw HTTPError(code: httpResponse.statusCode, message: message)
        }
        
        throw HTTPError(code: httpResponse.statusCode)
    }
    
    return data
}


/// A wrapper for HTTP request and response handling
/// - Parameters:
///   - path: The path of URL endpoint
///   - base: Base URL
///   - protected: Whether the endpoint needs authentication
///   - params: URL queries
///   - payload: JSON payload
///   - method: HTTP method. If not provided, it will be set to GET, if not payload is provided, it will be set to POST
/// - Returns: Decoded JSON response
func requestWithResponse<T: Decodable>(_ path: String, base: URL, protected: Bool = true, params: [String: String]? = nil, payload: [String: Any]? = nil, method: String? = nil) async throws -> T {
    let data = try await requestWithData(path, base: base, protected: protected, params: params, payload: payload, method: method)
    return try JSONDecoder.defaultDecoder.decode(T.self, from: data)
}

/// A wrapper for HTTP request and response handling, without returing response
/// - Parameters:
///   - path: The path of URL endpoint
///   - base: Base URL
///   - protected: Whether the endpoint needs authentication
///   - params: URL queries
///   - payload: JSON payload
///   - method: HTTP method. If not provided, it will be set to GET, if not payload is provided, it will be set to POST
func requestWithoutResponse(_ path: String, base: URL, protected: Bool = true, params: [String: String]? = nil, payload: [String: Any]? = nil, method: String? = nil) async throws {
    _ = try await requestWithData(path, base: base, protected: protected, params: params, payload: payload, method: method)
}

struct HTTPError: Error {
    let code: Int
    let message: String?
    
    init(code: Int, message: String? = nil) {
        self.code = code
        self.message = message
    }
}

extension HTTPError: LocalizedError {
    var errorDescription: String? {
        let localizedCodeDescription = HTTPURLResponse.localizedString(forStatusCode: code)
        if let message {
            return localizedCodeDescription + " " + message
        }
        return localizedCodeDescription
    }
}

enum TokenError: Error {
    case none
    case expired
}

extension TokenError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .none:
            String(localized: "Token not found.", bundle: .module)
        case .expired:
            String(localized: "Token has expired, please login again.", bundle: .module)
        }
    }
}

