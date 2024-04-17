import Foundation

public struct CourseGroup: Identifiable, Hashable, Decodable {
    public let id: Int
    public let name: String
    public let code: String
    public let department: String
    public let campus: String
    public let courses: [Course]
}

public struct Course: Identifiable, Hashable, Decodable {
    public let id: Int
    public let credit: Double
    public let name, code, codeId, department, campus, teachers: String
    public let maxStudent, weekHour, year, semester: Int
    public let reviews: [Review]
}

public struct Review: Identifiable, Hashable, Codable {
    public let id, reviewerId: Int
    public let title, content: String
    public let timeCreated, timeUpdated: Date
    public let isMe: Bool
    public let remark: Int
    public let vote: Int
    public let rank: Rank
}

public struct Rank: Codable, Hashable {
    public let overall, content, workload, assessment: Double
}
