import Foundation

// MARK: - Course Table

/// A semester
///
/// Use ``name`` to get the formatted name of the semester.
public struct Semester: Codable {
    public enum SemesterType: Int, Codable, Hashable {
        case first = 0, winter, second, summer
    }
    
    let year: Int
    let type: SemesterType
    public let semesterId: Int
    public var startDate: Date?
    public let weekCount: Int
}

extension Semester: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(year)
        hasher.combine(type)
        hasher.combine(semesterId)
    }
}

extension Semester: Equatable {
    public static func == (lhs: Semester, rhs: Semester) -> Bool {
        let yearEqual = lhs.year == rhs.year
        let typeEqual = lhs.type == rhs.type
        let semesterIdEqual = lhs.semesterId == rhs.semesterId
        return yearEqual && typeEqual && semesterIdEqual
    }
}

extension Semester: Comparable {
    public static func < (lhs: Semester, rhs: Semester) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }
        
        return lhs.type.rawValue < rhs.type.rawValue
    }
}

extension Semester {
    /// Formatted name of the semester
    public var name: String {
        let semesterName = switch type {
        case .first: "第一学期"
        case .winter: "寒假学期"
        case .second: "第二学期"
        case .summer: "暑假学期"
        }
        
        return "\(year)-\(year + 1)年\(semesterName)"
    }
}

/// A course took by a student.
public struct Course: Identifiable, Codable, Hashable {
    public let id: UUID
    public let name, code, teacher, location: String
    public let weekday: Int
    public let start, end: Int
    public let onWeeks: [Int]
}

/// Time slot that courses are held.
///
/// All possible time slots have been created.
/// Do not create your own time slot.
/// Retrieve time slot by calling ``getItem(_:)``
public struct ClassTimeSlot {
    public let id: Int
    public let start, end: Date
}

extension ClassTimeSlot {
    init(_ id: Int, _ start: String, _ end: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        self.id = id
        // start and end are specified in below, it cannot in incorrect format
        // it's safe to use force unwrap
        self.start = formatter.date(from: start)!
        self.end = formatter.date(from: end)!
    }
    
    static let list = [ClassTimeSlot(1, "08:00", "08:45"),
                              ClassTimeSlot(2, "08:55", "09:40"),
                              ClassTimeSlot(3, "09:55", "10:40"),
                              ClassTimeSlot(4, "10:50", "11:35"),
                              ClassTimeSlot(5, "11:45", "12:30"),
                              ClassTimeSlot(6, "13:30", "14:15"),
                              ClassTimeSlot(7, "14:25", "15:10"),
                              ClassTimeSlot(8, "15:25", "16:10"),
                              ClassTimeSlot(9, "16:20", "17:05"),
                              ClassTimeSlot(10, "17:15", "18:00"),
                              ClassTimeSlot(11, "18:30", "19:15"),
                              ClassTimeSlot(12, "19:25", "20:10"),
                              ClassTimeSlot(13, "20:20", "21:05"),
                              ClassTimeSlot(14, "21:15", "22:00")]
    
    public static func getItem(_ i: Int) -> ClassTimeSlot {
        return list[i - 1]
    }
}

// MARK: - GPA and Score

/// The score of a course
public struct Score: Identifiable, Codable {
    public let id: UUID
    public let courseId: String
    public let courseName: String
    public let courseType: String
    public let courseCredit: String
    public let grade: String
    public let gradePoint: String
}

/// A rank entry in the rank table
public struct Rank: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let grade, major, department: String
    public let gradePoint, credit: Double
    public let rank: Int
    
    public var isMe: Bool {
        !name.contains("*")
    }
}
