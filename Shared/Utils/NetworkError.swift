import Foundation

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
