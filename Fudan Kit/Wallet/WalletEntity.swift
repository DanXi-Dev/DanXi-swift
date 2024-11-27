import Foundation

/// eCard transaction record
public struct Transaction: Identifiable, Codable {
    public let id: UUID
    public let date: Date
    public let location: String
    public let amount: Double
    public let remaining: Double
}

// Dummy data for preview
extension Transaction {
    public static var sampleTransactions: [Transaction] {
        [
            Transaction(
                id: UUID(),
                date: Date().addingTimeInterval(-36400),
                location: "Tokyo Station",
                amount: 1500.50,
                remaining: 2000.00
            ),
            Transaction(
                id: UUID(),
                date: Date().addingTimeInterval(-72800),
                location: "Shibuya Crossing",
                amount: 2500.00,
                remaining: 1000.00
            ),
            Transaction(
                id: UUID(),
                date: Date().addingTimeInterval(-259200),
                location: "Roppongi Hills",
                amount: 500.75,
                remaining: 1200.00
            )
        ]
    }
}
