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

public extension Semester {
    /// Formatted name of the semester
    var name: String {
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

    public func openOn(_ week: Int) -> Bool {
        onWeeks.contains(week)
    }
    
    func conflicts(with other: Course) -> Bool {
        guard weekday == other.weekday else {
            return false
        }
        guard !(end < other.start || start > other.end) else {
            return false
        }
        return !Set(onWeeks).isDisjoint(with: Set(other.onWeeks))
    }
}

/// Time slot that courses are held.
///
/// All possible time slots have been created.
/// Do not create your own time slot.
/// Retrieve time slot by calling ``getItem(_:)``
public struct ClassTimeSlot: Identifiable {
    public let id: Int
    public let start, end: Date
}

public extension ClassTimeSlot {
    internal init(_ id: Int, _ start: DateComponents, _ end: DateComponents) {
        self.id = id

        /*
         // start and end are specified in below, it cannot in incorrect format
         // it's safe to use force unwrap
          */
        self.start = start.date!
        self.end = end.date!
    }

    static let list = [ClassTimeSlot(1, DateComponents(calendar: Calendar.current, hour: 8, minute: 0), DateComponents(calendar: Calendar.current, hour: 8, minute: 45)),
                       ClassTimeSlot(2, DateComponents(calendar: Calendar.current, hour: 8, minute: 55), DateComponents(calendar: Calendar.current, hour: 9, minute: 40)),
                       ClassTimeSlot(3, DateComponents(calendar: Calendar.current, hour: 9, minute: 55), DateComponents(calendar: Calendar.current, hour: 10, minute: 40)),
                       ClassTimeSlot(4, DateComponents(calendar: Calendar.current, hour: 10, minute: 50), DateComponents(calendar: Calendar.current, hour: 11, minute: 35)),
                       ClassTimeSlot(5, DateComponents(calendar: Calendar.current, hour: 11, minute: 45), DateComponents(calendar: Calendar.current, hour: 12, minute: 30)),
                       ClassTimeSlot(6, DateComponents(calendar: Calendar.current, hour: 13, minute: 30), DateComponents(calendar: Calendar.current, hour: 14, minute: 15)),
                       ClassTimeSlot(7, DateComponents(calendar: Calendar.current, hour: 14, minute: 25), DateComponents(calendar: Calendar.current, hour: 15, minute: 10)),
                       ClassTimeSlot(8, DateComponents(calendar: Calendar.current, hour: 15, minute: 25), DateComponents(calendar: Calendar.current, hour: 16, minute: 10)),
                       ClassTimeSlot(9, DateComponents(calendar: Calendar.current, hour: 16, minute: 20), DateComponents(calendar: Calendar.current, hour: 17, minute: 5)),
                       ClassTimeSlot(10, DateComponents(calendar: Calendar.current, hour: 17, minute: 15), DateComponents(calendar: Calendar.current, hour: 18, minute: 0)),
                       ClassTimeSlot(11, DateComponents(calendar: Calendar.current, hour: 18, minute: 30), DateComponents(calendar: Calendar.current, hour: 19, minute: 15)),
                       ClassTimeSlot(12, DateComponents(calendar: Calendar.current, hour: 19, minute: 25), DateComponents(calendar: Calendar.current, hour: 20, minute: 10)),
                       ClassTimeSlot(13, DateComponents(calendar: Calendar.current, hour: 20, minute: 20), DateComponents(calendar: Calendar.current, hour: 21, minute: 5)),
                       ClassTimeSlot(14, DateComponents(calendar: Calendar.current, hour: 21, minute: 15), DateComponents(calendar: Calendar.current, hour: 22, minute: 0))]

    static func getItem(_ i: Int) -> ClassTimeSlot {
        return list[i - 1]
    }
}

// MARK: - Exam

public struct Exam: Identifiable {
    public let id: UUID
    public let courseId: String
    public let course: String
    public let type: String
    public let method: String
    public let semester: String
    public let date: String
    public let time: String
    public let location: String
    public let note: String
    public let isFinished: Bool
}

// MARK: - GPA and Score

/// The score of a course
public struct Score: Identifiable, Codable {
    public let id: UUID
    public let courseId: String
    public let courseName: String
    public let courseType: String
    public let courseCredit: String? // TODO: 新API暂不支持学分查询，后续补充
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
