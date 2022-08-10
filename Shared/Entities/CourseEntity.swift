import Foundation

struct DKCourseGroup: Hashable, Codable, Identifiable {
    let id: Int
    let name, code, department, campus: String
    let courses: [DKCourse]
}

struct DKCourse: Hashable, Codable, Identifiable {
    let id: Int
    let credit: Double
    let name, code, codeId, department, campus, teachers: String
    let maxStudent, weekHour, year, semester: Int
    let reviews: [DKReview]
}

struct DKReview: Hashable, Codable, Identifiable {
    let id, reviewerId: Int
    let title, content: String
    let remark: Int
//    let timeCreated, timeUpdated: Date
    // let rank ? (content, overall, workload, assessment: int)
    let isMe: Bool
    let vote: Int
}
