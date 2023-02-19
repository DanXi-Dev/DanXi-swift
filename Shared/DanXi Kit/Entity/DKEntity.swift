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
    
    enum CodingKeys: String, CodingKey {
        case id, name, code, department
        case campus = "campus_name"
        case courses = "course_list"
    }
}

struct DKCourse: Hashable, Codable, Identifiable {
    let id: Int
    let credit: Double
    let name, code, codeId, department, campus, teachers: String
    let maxStudent, weekHour, year, semester: Int
    let reviews: [DKReview]
    
    var formattedSemester: LocalizedStringResource {
        return DKSemester(year: year, semester: semester).formatted()
    }
    
    func matchSemester(_ semester: DKSemester) -> Bool {
        return self.year == semester.year && self.semester == semester.semester
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, code, department, teachers, year, semester, credit
        case codeId = "code_id"
        case campus = "campus_name"
        case maxStudent = "max_student"
        case weekHour = "week_hour"
        case reviews = "review_list"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        code = try values.decode(String.self, forKey: .code)
        codeId = try values.decode(String.self, forKey: .codeId)
        department = try values.decode(String.self, forKey: .department)
        campus = try values.decode(String.self, forKey: .campus)
        teachers = try values.decode(String.self, forKey: .teachers)
        maxStudent = try values.decode(Int.self, forKey: .maxStudent)
        weekHour = try values.decode(Int.self, forKey: .weekHour)
        year = try values.decode(Int.self, forKey: .year)
        semester = try values.decode(Int.self, forKey: .semester)
        credit = try values.decodeIfPresent(Double.self, forKey: .credit) ?? 0
        reviews = try values.decodeIfPresent([DKReview].self, forKey: .reviews) ?? []
    }
}

struct DKSemester: Identifiable, Hashable {
    var id: Int {
        year * 10 + semester
    }
    let year, semester: Int
    
    func formatted() -> LocalizedStringResource {
        switch semester {
        case 1:
            return LocalizedStringResource("\(String(year)) Fall Semester")
        case 2:
            return LocalizedStringResource("\(String(year)) Winter Vacation")
        case 3:
            return LocalizedStringResource("\(String(year)) Spring Semester")
        case 4:
            return LocalizedStringResource("\(String(year)) Winter Vacation")
        default:
            return LocalizedStringResource("\(String(year)) - \(semester)")
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
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, remark, vote, rank
        case reviewerId = "reviewer_id"
        case isMe = "is_me"
        case updateTime = "time_updated"
        case createTime = "time_created"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        reviewerId = try values.decode(Int.self, forKey: .reviewerId)
        title = try values.decode(String.self, forKey: .title)
        content = try values.decode(String.self, forKey: .content)
        remark = try values.decode(Int.self, forKey: .remark)
        
        isMe = try values.decode(Bool.self, forKey: .isMe)
        vote = try values.decode(Int.self, forKey: .vote)
        rank = try values.decode(DKRank.self, forKey: .rank)
        
        self.createTime = try decodeDate(values, key: .createTime)
        self.updateTime = try decodeDate(values, key: .updateTime)
    }
}

struct DKRank: Hashable, Codable {
    var overall, content, workload, assessment: Double
}
