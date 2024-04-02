import Foundation

/// The amount of electricity used in a single day
public struct ElectricityLog: Identifiable, Codable, Equatable {
    public let id: UUID
    public let date: Date
    public let usage: Float
}

/// The amount of money spent in a single day
public struct WalletLog: Identifiable, Codable {
    public let id: UUID
    public let date: Date
    public let amount: Float
}

/// User information from `my.fudan.edu.cn`, including ecard balance
public struct UserInfo: Codable {
    public let userId: String
    public let userName: String
    public let cardStatus: String
    public let entryPermission: String
    public let expirationDate: String
    public let balance: String
}

