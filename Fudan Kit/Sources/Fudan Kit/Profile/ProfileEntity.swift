import Foundation

/// Student profile, include student personal information.
public struct Profile: Codable {
    public let campusId: String
    public let name: String
    public let gender: String
    public let idNumber: String
    public let department: String
    public let major: String
}
