import Foundation

struct DKCourseGroup: Hashable, Codable, Identifiable {
    let id: Int
    let name, code, department, campus: String
    let courses: [DKCourse]
    
    var reviews: [DKReview] {
        var reviewList: [DKReview] = []
        for course in courses {
            reviewList.append(contentsOf: course.reviews)
        }
        return reviewList
    }
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
    let createTime, updateTime: Date
    let isMe: Bool
    let vote: Int
    let rank: DKRank
}

struct DKRank: Hashable, Codable {
    let content, overall, workload, assessment: Int
}
