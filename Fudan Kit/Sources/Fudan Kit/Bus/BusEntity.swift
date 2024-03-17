import Foundation

/// Campus bus route, e.g., 邯郸-江湾
public struct Route {
    public let start: String
    public let end: String
    public let schedules: [Schedule]
}

/// Campus bus schedule, e.g., 邯郸->江湾 13:00
public struct Schedule {
    public let id: Int
    public let time: Date
    public let start, end: String
    public let holiday: Bool
}
