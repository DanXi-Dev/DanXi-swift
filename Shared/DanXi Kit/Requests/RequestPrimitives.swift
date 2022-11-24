import Foundation

/// Request for a server response.
/// - Parameters:
///   - url: URL to query.
///   - method: HTTP method, default is `GET`.
/// - Returns: Server response decoded object.
func requestObj<T: Decodable>(url: URL,
                              method: String? = nil) async throws -> T {
    let responseData = try await networkRequest(url: url,
                                                method: method)
    do {
        return try JSONDecoder().decode(T.self, from: responseData)
    } catch {
        throw NetworkError.invalidResponse
    }
}

/// Request for a server response.
/// - Parameters:
///   - url: URL to query.
///   - payload: Payload object, should conform to `Encodable`.
///   - method: HTTP method, default is `GET` or `POST`, depending on whether `payload` is `nil`.
///   - authorize: Whether to add authorization token in request, default `true`.
/// - Returns: Server response decoded object.
func requestObj<T: Decodable, S: Encodable>(url: URL,
                                            payload: S,
                                            method: String? = nil,
                                            authorize: Bool = true) async throws -> T {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    let payloadData = try encoder.encode(payload)
    
    let responseData = try await networkRequest(url: url,
                                                data: payloadData,
                                                method: method,
                                                authorize: authorize)
    do {
        return try JSONDecoder().decode(T.self, from: responseData)
    } catch {
        throw NetworkError.invalidResponse
    }
}

/// Send request to server, ignore response.
/// - Parameters:
///   - url: URL to query.
///   - payload: Payload object, should conform to `Encodable`.
///   - method: HTTP method, default is `GET` or `POST`, depending on whether `payload` is `nil`.
func sendRequest<S: Encodable>(url: URL,
                               payload: S,
                               method: String? = nil) async throws {
    var payloadData: Data?
    
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    payloadData = try encoder.encode(payload)
    
    _ = try await networkRequest(url: url,
                                 data: payloadData,
                                 method: method)
}

/// Send request to server, ignore response.
/// - Parameters:
///   - url: URL to query.
///   - method: HTTP method, default is `GET`.
func sendRequest(url: URL, method: String? = nil) async throws {
    _ = try await networkRequest(url: url, method: method)
}

/// Network request primitive, add necessary HTTP headers and authentication infomation.
/// - Parameters:
///   - url: URL to query.
///   - data: data to upload.
///   - method: HTTP method, default is `GET` or `POST`, depending on whether `data` is `nil`.
///   - authorize: Whether to add authorization token in request, default `true`.
///   - retry: internal parameter, used to prevent infinite recursion when refreshing token is needed.
/// - Returns: Server response data.
func networkRequest(url: URL,
                    data: Data? = nil,
                    method: String? = nil,
                    authorize: Bool = true,
                    retry: Bool = false) async throws -> Data {
    struct ServerMessage: Codable {
        let message: String
    }
    
    var request = URLRequest(url: url)
    
    if authorize {
        guard let token = SecStore.shared.token else {
            throw DanXiError.tokenNotFound
        }
        request.setValue("Bearer \(token.access)", forHTTPHeaderField: "Authorization")
    }
    
    if let payloadData = data {
        request.httpMethod = method ?? "POST"
        request.httpBody = payloadData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    } else {
        request.httpMethod = method ?? "GET"
    }
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200..<300:
                return data
            case 401:
                if retry || !authorize {
                    throw HTTPError.unauthorized
                }
                
                // refresh token and retry
                try await AuthDelegate.shared.refreshToken()
                return try await networkRequest(url: url, data: data, method: method, retry: true)
            case 403:
                throw HTTPError.forbidden
            case 404:
                throw HTTPError.notFound
            case 400..<500:
                let serverResponse = try? JSONDecoder().decode(ServerMessage.self, from: data)
                throw HTTPError.clientError(message: serverResponse?.message ?? "")
            case 500..<600:
                let serverResponse = try? JSONDecoder().decode(ServerMessage.self, from: data)
                throw HTTPError.serverError(message: serverResponse?.message ?? "")
            default:
                throw NetworkError.invalidResponse
            }
        } else {
            throw NetworkError.invalidResponse
        }
    } catch let error as URLError {
        throw NetworkError.networkError(message: error.localizedDescription)
    }
}
