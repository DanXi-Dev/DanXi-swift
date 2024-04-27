import Foundation

/// Campus bus route, e.g., 邯郸-江湾
public struct Route {
    public let start: String
    public let end: String
    public let schedules: [Schedule]
    
    public init(start: String, end: String, schedules: [Schedule]) {
        self.start = start
        self.end = end
        self.schedules = schedules
    }
}

/// Campus bus schedule, e.g., 邯郸->江湾 13:00
public struct Schedule: Identifiable {
    public let id: Int
    public var time: Date
    public let start, end: String
    public let holiday: Bool
    public let bidirectional: Bool
    public var missed = false
    
    public init(id: Int, time: Date, start: String, end: String, holiday: Bool, bidirectional: Bool, missed: Bool = false) {
        self.id = id
        self.time = time
        self.start = start
        self.end = end
        self.holiday = holiday
        self.bidirectional = bidirectional
        self.missed = missed
    }
}
