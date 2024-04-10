import Foundation

// MARK: - Prepare

func prepareRequest(_ url: URL,
                    payload: Data? = nil, method: String? = nil) -> URLRequest {
    var request = URLRequest(url: url)
    
    // set user agent
    request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15",
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

func prepareJSONRequest<S: Encodable>(_ url: URL,
                                      payload: S, method: String? = nil) throws -> URLRequest {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(payload)
    
    var request = prepareRequest(url, payload: data, method: method)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    return request
}

// MARK: - Request

func sendRequest(_ urlString: String) async throws -> (Data, URLResponse) {
    let url = URL(string: urlString)!
    let request = URLRequest(url: url)
    return try await sendRequest(request)
}

func sendRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
        throw HTTPError(data: data, response: response)
    }
    
    switch httpResponse.statusCode {
    case 200..<300:
        return (data, response)
    default:
        throw HTTPError(data: data, response: response)
    }
}


// MARK: - Process

func processJSONData<T: Decodable>(_ data: Data) throws -> T {
    do {        
        return try JSONDecoder().decode(T.self, from: data)
    } catch {
        throw ParseError.invalidJSON
    }
}

func decodeDate(_ date: String) throws -> Date {
    let formatter = ISO8601DateFormatter()
    
    var iso8601TimeString = date
    if !iso8601TimeString.contains("+") && !iso8601TimeString.contains("Z") {
        iso8601TimeString.append("+00:00") // add timezone manually
    }
    
    if iso8601TimeString.contains(".") {
        formatter.formatOptions = [.withTimeZone, .withFractionalSeconds, .withInternetDateTime]
    } else {
        formatter.formatOptions = [.withTimeZone, .withInternetDateTime]
    }
    if let date = formatter.date(from: iso8601TimeString) {
        return date
    }
    throw ParseError.invalidDateFormat
}

func decodeDate<K: CodingKey>(_ values: KeyedDecodingContainer<K>, key: KeyedDecodingContainer<K>.Key) throws -> Date {
    var iso8601TimeString = try values.decode(String.self, forKey: key)
    let formatter = ISO8601DateFormatter()
    
    if !iso8601TimeString.contains("+") && !iso8601TimeString.contains("Z") {
        iso8601TimeString.append("+00:00") // add timezone manually
    }
    
    if iso8601TimeString.contains(".") {
        formatter.formatOptions = [.withTimeZone, .withFractionalSeconds, .withInternetDateTime]
    } else {
        formatter.formatOptions = [.withTimeZone, .withInternetDateTime]
    }
    if let date = formatter.date(from: iso8601TimeString) {
        return date
    }
    throw ParseError.invalidDateFormat
}

// MARK: - Error

public struct HTTPError: LocalizedError {
    let code: Int
    let response: URLResponse
    let data: Data
    let message: String?
    
    init(data: Data, response: URLResponse) {
        struct ErrorMessage: Codable {
            let message: String
        }
        
        self.data = data
        self.response = response
        if let httpResponse = response as? HTTPURLResponse {
            self.code = httpResponse.statusCode
        } else {
            self.code = 0
        }
        let messageBody = try? JSONDecoder().decode(ErrorMessage.self, from: data)
        self.message = messageBody?.message
    }
    
    public var errorDescription: String? {
        if let message = self.message {
            let localized = NSLocalizedString("%@: %@", comment: "")
            return String(format: localized, String(code), message)
        }
        let localized = NSLocalizedString("Error %@", comment: "")
        return String(format: localized, String(code))
    }
}

public enum ParseError: LocalizedError {
    case invalidResponse
    case invalidHTTP
    case invalidJSON
    case invalidHTML
    case invalidDateFormat
    case invalidEncoding
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return NSLocalizedString("Cannot parse server response", comment: "")
        case .invalidHTTP:
            return NSLocalizedString("Invalid HTTP response", comment: "")
        case .invalidJSON:
            return NSLocalizedString("Cannot parse JSON response", comment: "")
        case .invalidHTML:
            return NSLocalizedString("Cannot parse HTML response", comment: "")
        case .invalidDateFormat:
            return NSLocalizedString("Invalid date format", comment: "")
        case .invalidEncoding:
            return NSLocalizedString("Invalid encoding", comment: "")
        }
    }
}
