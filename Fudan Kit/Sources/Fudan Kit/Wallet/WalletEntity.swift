import Foundation

/// eCard transaction record
public struct Transaction: Identifiable, Codable {
    public let id: UUID
    public let date: Date
    public let location: String
    public let amount: Double
    public let remaining: Double
}

/// User info from my.fudan.edu.cn
public struct UserInfo: Codable {
    public let userId: String
    public let userName: String
    public let cardStatus: String
    public let entryPermission: String
    public let expirationDate: String
    public let balance: String
}

public struct DateBoundValueData: Codable, Equatable {
    public var date: Date
    public var value: Float
}
