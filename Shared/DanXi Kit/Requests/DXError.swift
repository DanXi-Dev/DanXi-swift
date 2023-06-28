import Foundation

enum DXError: LocalizedError {
    case tokenExpired
    case tokenNotFound
    case banned
    case loginFailed
    case registerFailed(message: String)
    case holeNotExist(holeId: Int)
    case floorNotExist(floorId: Int)
    case invalidRecipientsFormat
    
    public var errorDescription: String? {
        switch self {
        case .tokenExpired:
            return NSLocalizedString("Token expired, login again", comment: "")
        case .tokenNotFound:
            return NSLocalizedString("Token not initialized, contact developer for help", comment: "")
        case .banned:
            return NSLocalizedString("Banned by admin", comment: "")
        case .loginFailed:
            return NSLocalizedString("Incorrect username or password", comment: "")
        case .registerFailed(let message):
            return String(format: NSLocalizedString("Register failed: %@", comment: ""), message)
        case .holeNotExist(let holeId):
            return String(format: NSLocalizedString("Treehole #%@ not exist", comment: ""), String(holeId))
        case .floorNotExist(let floorId):
            return String(format: NSLocalizedString("Floor ##%@ not exist", comment: ""), String(floorId))
        case .invalidRecipientsFormat:
            return NSLocalizedString("Invalid Recipients Format", comment: "")
        }
    }
}
