import Foundation

/// All buildings that host courses
public enum Building: String {
    case empty = ""
    case h2 = "H2"
    case h3 = "H3"
    case h4 = "H4"
    case h5 = "H5"
    case h6 = "H6"
    case hgx = "HGX"
    case hgd = "HGD"
    case hq = "HQ"
    case j = "J"
    case z = "Z"
    case f = "F"
}

/// A classroom, which contains a list of schedules
public struct Classroom: Identifiable {
    public let id: UUID
    public let name: String
    public let capacity: String
    public let schedules: [CourseSchedule]
}

/// A schedule of a course, which takes place at a certain classroom at a given time
public struct CourseSchedule: Codable {
    public let id: UUID
    public let start: Int
    public let end: Int
    public let name: String
    public let courseId: String
    public let category: String?
    public let teacher: String?
    public let capacity: String?
}
