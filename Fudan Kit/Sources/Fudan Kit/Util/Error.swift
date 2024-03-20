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
            return String(localized: "Credential not found, login again", comment: "")
        case .needCaptcha:
            return String(localized: "Need captcha, visit UIS webpage to login", comment: "")
        case .loginFailed:
            return String(localized: "Login failed, check username and password", comment: "")
        case .campusOnly:
            return String(localized: "Service unavailable, connect to campus WiFi or VPN to access", comment: "")
        case .notDiningTime:
            return String(localized: "Not in dining time", comment: "")
        case .termsNotAgreed:
            return String(localized: "Terms not Agreed", comment: "")
        case .customError(let message):
            return String(format: NSLocalizedString("Error: %@", comment: ""), message)
        }
    }
}
