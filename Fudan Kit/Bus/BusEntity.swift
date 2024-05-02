import Foundation

public struct BusRoutes: Codable {
    public let workday: [Route]
    public let weekend: [Route]
}

/// Campus bus route, e.g., 邯郸-江湾
public struct Route: Codable {
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
public struct Schedule: Identifiable, Codable {
    public let id: Int
    public let time: Date
    public let start, end: String
    public let holiday: Bool
    public let bidirectional: Bool
    public var missed: Bool {
        get {
            let current = Date.now
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute, .second], from: current)
            // the `current` date part is not the same with `schedule.time` date part
            // `current` need to be normalized before comparing
            if let normalizedCurrent = calendar.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: components.second ?? 0, of: self.time) {
                return self.time < normalizedCurrent
            }
            return false
        }
    }
    
    public init(id: Int, time: Date, start: String, end: String, holiday: Bool, bidirectional: Bool) {
        self.id = id
        self.time = time
        self.start = start
        self.end = end
        self.holiday = holiday
        self.bidirectional = bidirectional
    }
}
