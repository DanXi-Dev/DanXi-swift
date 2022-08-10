import Foundation
import SwiftUI

public enum NetworkError: Error {
    case networkError
    case invalidResponse
    case forbidden
    case unauthorized
    case notInitialized
    case invalidRequest(message: String)
    case serverError(message: String)
    
    public var localizedErrorDescription: NetworkErrorInfo {
        switch self {
        case .networkError:
            return NetworkErrorInfo(title: "Network Error", description: "Network error, try again later")
        case .invalidResponse:
            return NetworkErrorInfo(title: "Invalid Response", description: "Server response is invalid")
        case .forbidden:
            return NetworkErrorInfo(title: "Forbidden", description: "Operation forbidden")
        case .unauthorized:
            return NetworkErrorInfo(title: "Unauthorized", description: "Invalid credential")
        case .notInitialized:
            return NetworkErrorInfo(title: "Not Initialized", description: "Credential not initialized, contact developer for help")
        case .invalidRequest(let message):
            return NetworkErrorInfo(title: "Invalid Request", description: "Request invalid, contact developer for help. message: \(message)")
        case .serverError(let message):
            return NetworkErrorInfo(title: "Server Error", description: "Internal server error. message: \(message)")
        }
    }
}

public struct NetworkErrorInfo {
    var title: LocalizedStringKey = ""
    var description: LocalizedStringKey = ""
}
