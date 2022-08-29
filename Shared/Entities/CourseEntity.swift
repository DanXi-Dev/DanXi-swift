import Foundation
import SwiftUI

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
    
    var teachers: [String] {
        var teachers = Set<String>()
        for course in courses {
            teachers.insert(course.teachers)
        }
        return Array(teachers)
    }
    
    var semesters: [DKSemester] {
        var semesters = Set<DKSemester>()
        for course in courses {
            let semester = DKSemester(year: course.year,
                                      semester: course.semester)
            semesters.insert(semester)
        }
        return Array(semesters)
    }
}

struct DKCourse: Hashable, Codable, Identifiable {
    let id: Int
    let credit: Double
    let name, code, codeId, department, campus, teachers: String
    let maxStudent, weekHour, year, semester: Int
    let reviews: [DKReview]
    
    var formattedSemester: LocalizedStringKey {
        return DKSemester(year: year, semester: semester).formatted()
    }
    
    func matchSemester(_ semester: DKSemester) -> Bool {
        return self.year == semester.year && self.semester == semester.semester
    }
}

struct DKSemester: Identifiable, Hashable {
    var id: Int {
        year * 10 + semester
    }
    let year, semester: Int
    
    func formatted() -> LocalizedStringKey {
        switch semester {
        case 1:
            return "\(String(year)) Fall Semester"
        case 2:
            return "\(String(year)) Winter Vacation"
        case 3:
            return "\(String(year)) Spring Semester"
        case 4:
            return "\(String(year)) Winter Vacation"
        default:
            return "\(String(year)) - \(semester)"
        }
    }
    
    static let empty = DKSemester(year: 0, semester: -1)
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
    let overall, content, workload, assessment: Double
}
