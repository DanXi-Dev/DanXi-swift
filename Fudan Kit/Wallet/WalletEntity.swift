import Foundation

/// eCard transaction record
public struct Transaction: Identifiable, Codable {
    public let id: UUID
    public let date: Date
    public let location: String
    public let amount: Double
    public let remaining: Double
    public let sign: String
    
    public init(id: UUID, date: Date, location: String, amount: Double, remaining: Double, sign: String) {
        self.id = id
        self.date = date
        self.location = location
        self.amount = amount
        self.remaining = remaining
        self.sign = sign
    }
}

public struct WalletContent: Codable {
    public let balance: String
    public let transactions: [Transaction]
    public let logs: [WalletLog]
}
