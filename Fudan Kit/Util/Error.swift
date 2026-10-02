import Foundation

public enum CampusError: Error {
    case credentialNotFound
    case needCaptcha
    case loginFailed
    case campusOnly
    case notDiningTime
    case termsNotAgreed
    case customError(message: String)
}

extension CampusError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .credentialNotFound:
            return String(localized: "Credential not found, login again", bundle: .module)
        case .needCaptcha:
            return String(localized: "Need captcha, visit UIS webpage to login", bundle: .module)
        case .loginFailed:
            return String(localized: "Login failed, check username and password", bundle: .module)
        case .campusOnly:
            return String(localized: "Service unavailable, connect to campus WiFi or VPN to access", bundle: .module)
        case .notDiningTime:
            return String(localized: "Not in dining time", bundle: .module)
        case .termsNotAgreed:
            return String(localized: "Terms not Agreed", bundle: .module)
        case .customError(let message):
            return String(localized: "Error: \(message)", bundle: .module)
        }
    }
}
