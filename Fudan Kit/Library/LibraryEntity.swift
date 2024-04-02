import Foundation

/// A library and its relative information, including the number of people and capacity
public struct Library: Identifiable, Codable {
    public let id: Int
    public let name: String
    public let current, capacity: Int
    public let openTime: String
}
