import Foundation

public enum FDError: Error {
    case credentialNotFound
    case needCaptcha
    case campusOnly
    case notDiningTime
}
