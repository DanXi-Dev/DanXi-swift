import Foundation

/// A collection of dining rooms in a campus
public struct Canteen: Identifiable, Codable {
    public let id: UUID
    public let campus: String
    public let diningRooms: [DiningRoom]
}


/// A canteen window and correspondng queuing status
public struct DiningRoom: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let current: Int
    public let capacity: Int
}
