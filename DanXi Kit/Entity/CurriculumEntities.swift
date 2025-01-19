import Foundation

public struct CourseGroup: Identifiable, Hashable, Codable {
    public let id: Int
    public let name: String
    public let code: String
    public let department: String
    public let campus: String
    public var courses: [Course]
}

public struct Course: Identifiable, Hashable, Codable {
    public let id: Int
    public let credit: Double
    public let name, code, codeId, department, campus, teachers: String
    public let maxStudent, weekHour, year, semester: Int
    public var reviews: [Review]
}

public struct Review: Identifiable, Hashable, Codable {
    public let id, reviewerId: Int
    public let title, content: String
    public let timeCreated, timeUpdated: Date
    public let isMe: Bool
    public let remark: Int
    public let vote: Int
    public let rank: Rank
    public let extra: Extra
    public struct Extra: Hashable, Codable {
        public let achievements: [Achievement]
        public struct Achievement: Hashable, Codable {
            public let name: String
            public let obtainDate: Date
            public let domain: String
        }
    }
}

public struct CurriculumSensitive: Identifiable, Hashable, Decodable {
    public let id: Int
    public let timeCreated, timeUpdated: Date
    public let title, content: String
    public let humanReviewedSensitive: Bool?
    public let sensitiveReason: String?
}

public struct Rank: Codable, Hashable {
    public let overall, content, workload, assessment: Double
    
    public init(overall: Double, content: Double, workload: Double, assessment: Double) {
        self.overall = overall
        self.content = content
        self.workload = workload
        self.assessment = assessment
    }
}

