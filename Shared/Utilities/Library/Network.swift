import Foundation
import SwiftSoup


// MARK: - Prepare

func prepareRequest(_ url: URL,
                    payload: Data? = nil, method: String? = nil) -> URLRequest {
    var request = URLRequest(url: url)
    
    // set user agent
    if request.allHTTPHeaderFields == nil {
        request.allHTTPHeaderFields = ["User-Agent" : "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15"]
    } else {
        request.allHTTPHeaderFields!["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15"
    }
    
    // set method and payload
    if let payload = payload {
        request.httpBody = payload
        request.httpMethod = method ?? "POST"
    } else {
        request.httpMethod = method ?? "GET"
    }
    
    return request
}

func prepareJSONRequest<S: Encodable>(_ url: URL,
                                      payload: S, method: String? = nil) throws -> URLRequest {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(payload)
    
    var request = prepareRequest(url, payload: data, method: method)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    return request
}

func prepareFormRequest(_ url: URL, method: String = "POST", form: [URLQueryItem]) -> URLRequest {
    var request = prepareRequest(url, method: method)
    request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    var requestBodyComponents = URLComponents()
    requestBodyComponents.queryItems = form
    request.httpBody = requestBodyComponents.query?.data(using: .ascii)
    
    return request
}


// MARK: - Request

func sendRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
    struct ServerMessage: Codable {
        let message: String
    }
    
    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200..<300:
            return (data, response)
        case 401:
            throw HTTPError.unauthorized
        case 403:
            throw HTTPError.forbidden
        case 404:
            throw HTTPError.notFound
        case 400..<500:
            let serverResponse = try? JSONDecoder().decode(ServerMessage.self, from: data)
            throw HTTPError.serverError(message: serverResponse?.message ?? "")
        case 500..<600:
            let serverResponse = try? JSONDecoder().decode(ServerMessage.self, from: data)
            throw HTTPError.serverError(message: serverResponse?.message ?? "")
        default:
            throw NetworkError.invalidResponse
        }
    } catch let error as URLError {
        throw NetworkError.networkError(message: error.localizedDescription)
    }
}


// MARK: - Process

func processJSONData<T: Decodable>(_ data: Data) throws -> T {
    do {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try JSONDecoder().decode(T.self, from: data)
    } catch {
        throw NetworkError.invalidResponse
    }
}

func processHTMLData(_ data: Data) throws -> Document {
    do {
        guard let htmlText = String(data: data, encoding: String.Encoding.utf8) else {
            throw NetworkError.invalidResponse
        }
        return try SwiftSoup.parse(htmlText)
    } catch {
        throw NetworkError.invalidResponse
    }
}

func processHTMLData(_ data: Data, selector: String) throws -> Element {
    do {
        guard let htmlText = String(data: data, encoding: String.Encoding.utf8) else {
            throw NetworkError.invalidResponse
        }
        let doc = try SwiftSoup.parse(htmlText)
        guard let element = try doc.select(selector).first() else {
            throw NetworkError.invalidResponse
        }
        return element
    } catch {
        throw NetworkError.invalidResponse
    }
}


// MARK: - Error

public enum HTTPError: LocalizedError {
    /// Bad request, HTTP 400.
    case badRequest(message: String)
    /// User are not logged in, HTTP 401.
    case unauthorized
    /// User does not have the privilege to perform the operation, HTTP 403.
    case forbidden
    /// Resource not found, HTTP 404.
    case notFound
    /// Client error, HTTP 4XX.
    case clientError(message: String)
    /// Server error, HTTP 5XX.
    case serverError(message: String)
    
    public var errorDescription: String? {
        switch self {
        case .badRequest(let message):
            return String(format: NSLocalizedString("Request invalid, contact developer for help. message: %@", comment: ""), message)
        case .forbidden:
            return NSLocalizedString("Operation forbidden", comment: "")
        case .unauthorized:
            return NSLocalizedString("Invalid credential", comment: "")
        case .notFound:
            return NSLocalizedString("Requested resourse not found", comment: "")
        case .clientError(message: let message):
            return message
        case .serverError(let message):
            return String(format: NSLocalizedString("Internal server error. message: %@", comment: ""), message)
        }
    }
}


public enum NetworkError: LocalizedError {
    /// Network connection cannot be established.
    case networkError(message: String)
    /// Server response cannot be decoded into corresponding objects.
    case invalidResponse
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return String(format: NSLocalizedString("Network error: %@", comment: ""), message)
        case .invalidResponse:
            return NSLocalizedString("Server response is invalid", comment: "")
        }
    }
}
