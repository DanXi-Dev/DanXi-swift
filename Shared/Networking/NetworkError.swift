import Foundation
import SwiftUI

public enum NetworkError: Error {
    case networkError
    case invalidResponse
    case forbidden
    case unauthorized
    case notFound
    case notInitialized // make network request without token, representing a bug
    case invalidRequest(message: String)
    case serverError(message: String)
    case ignore // reserved for SwiftUI bug causing URLSession to cancel
    
    public var localizedErrorDescription: ErrorInfo {
        switch self {
        case .networkError:
            return ErrorInfo(title: "Network Error", description: "Network error, try again later")
        case .invalidResponse:
            return ErrorInfo(title: "Invalid Response", description: "Server response is invalid")
        case .forbidden:
            return ErrorInfo(title: "Forbidden", description: "Operation forbidden")
        case .unauthorized:
            return ErrorInfo(title: "Unauthorized", description: "Invalid credential")
        case .notFound:
            return ErrorInfo(title: "Not Found", description: "Requested resourse not found")
        case .notInitialized:
            return ErrorInfo(title: "Not Initialized", description: "Credential not initialized, contact developer for help")
        case .invalidRequest(let message):
            return ErrorInfo(title: "Invalid Request", description: "Request invalid, contact developer for help. message: \(message)")
        case .serverError(let message):
            return ErrorInfo(title: "Server Error", description: "Internal server error. message: \(message)")
        case .ignore:
            return ErrorInfo()
        }
    }
}

public struct ErrorInfo {
    var title: LocalizedStringKey = ""
    var description: LocalizedStringKey = ""
}
