import Foundation

extension URLSession {
    static let campusSession = URLSession(configuration: .default)
}

/// Construct a `URLRequest` based on the information provided.
///
/// This function will:
/// - Set the value of User-Agent to prevent rejection by campus server
/// - Automatically set method to be `POST` if there is a `payload` param. The HTTP method can also be explicitly designated
func constructRequest(_ url: URL, payload: Data? = nil, method: String? = nil) -> URLRequest {
    var request = URLRequest(url: url)
    
    // set user agent
    let appVersion = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0.0.0"
    let ua = "DXSwift/\(appVersion)"
    request.setValue(ua,
                     forHTTPHeaderField: "User-Agent")
    
    // set method and payload
    if let payload = payload {
        request.httpBody = payload
        request.httpMethod = method ?? "POST"
    } else {
        request.httpMethod = method ?? "GET"
    }
    
    return request
}

/// Construct a `URLRequest` which submit a form.
func constructFormRequest(_ url: URL, method: String = "POST", form: [String: String]) -> URLRequest {
    var request = constructRequest(url, method: method)
    request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    // convert [String: String] to [URLQueryItem]
    var queryItems: [URLQueryItem] = []
    for (key, value) in form {
        queryItems.append(URLQueryItem(name: key, value: value))
    }
    
    var requestBodyComponents = URLComponents()
    requestBodyComponents.queryItems = queryItems
    request.httpBody = requestBodyComponents.query?.data(using: .ascii)
    
    return request
}
