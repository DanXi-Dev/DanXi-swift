import Foundation

/// eCard transaction record
public struct Transaction: Identifiable, Codable {
    public let id: UUID
    public let date: Date
    public let location: String
    public let amount: Double
    public let remaining: Double
}
