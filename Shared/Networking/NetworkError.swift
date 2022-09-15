import Foundation
import SwiftUI

/// Error returned by requesting FDUHole API.
public enum NetworkError: Error {
    /// Network connection cannot be established.
    case networkError(message: String)
    /// Accessing protected API without initializing token, representing a bug.
    case notInitialized
    /// Server response cannot be decoded into corresponding objects.
    case invalidResponse
    /// Bad request, HTTP 400.
    case invalidRequest(message: String)
    /// User are not logged in, HTTP 401.
    case unauthorized
    /// User does not have the privilege to perform the operation, HTTP 403.
    case forbidden
    /// Resource not found, HTTP 404.
    case notFound
    /// Server error, HTTP 5XX.
    case serverError(message: String)
    /// Reserved for SwiftUI bug causing URLSession to cancel.
    case ignore
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return String(format: NSLocalizedString("Network error: %@", comment: ""), message)
        case .invalidResponse:
            return NSLocalizedString("Server response is invalid", comment: "")
        case .forbidden:
            return NSLocalizedString("Operation forbidden", comment: "")
        case .unauthorized:
            return NSLocalizedString("Invalid credential", comment: "")
        case .notFound:
            return NSLocalizedString("Requested resourse not found", comment: "")
        case .notInitialized:
            return NSLocalizedString("Credential not initialized, contact developer for help", comment: "")
        case .invalidRequest(let message):
            return String(format: NSLocalizedString("Request invalid, contact developer for help. message: %@", comment: ""), message)
        case .serverError(let message):
            return String(format: NSLocalizedString("Internal server error. message: %@", comment: ""), message)
        case .ignore:
            return NSLocalizedString("", comment: "")
        }
    }
}
