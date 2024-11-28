import Foundation

/// eCard transaction record
public struct Transaction: Identifiable, Codable {
    public let id: UUID
    public let date: Date
    public let location: String
    public let amount: Double
    public let remaining: Double
    
    public init(id: UUID, date: Date, location: String, amount: Double, remaining: Double) {
        self.id = id
        self.date = date
        self.location = location
        self.amount = amount
        self.remaining = remaining
    }
}
