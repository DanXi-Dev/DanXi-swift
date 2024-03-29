import Foundation

public enum FDError: Error {
    case credentialNotFound
    case needCaptcha
    case loginFailed
    case campusOnly
    case notDiningTime
    case termsNotAgreed
    case customError(message: String)
}

extension FDError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .credentialNotFound:
            return NSLocalizedString("Credential not found, login again", comment: "")
        case .needCaptcha:
            return NSLocalizedString("Need captcha, visit UIS webpage to login", comment: "")
        case .loginFailed:
            return NSLocalizedString("Login failed, check username and password", comment: "")
        case .campusOnly:
            return NSLocalizedString("Service unavailable, connect to campus WiFi or VPN to access", comment: "")
        case .notDiningTime:
            return NSLocalizedString("Not in dining time", comment: "")
        case .termsNotAgreed:
            return NSLocalizedString("Terms not Agreed", comment: "")
        case .customError(let message):
            return String(format: NSLocalizedString("Error: %@", comment: ""), message)
        }
    }
}
