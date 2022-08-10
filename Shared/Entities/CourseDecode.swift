import Foundation

extension DKCourseGroup {
    enum CodingKeys: String, CodingKey {
        case id, name, code, department
        case campus = "campus_name"
        case courses = "course_list"
    }
}

extension DKCourse {
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

extension DKReview {
    enum CodingKeys: String, CodingKey {
        case id, title, content, remark, vote
        case reviewerId = "reviewer_id"
        case isMe = "is_me"
//        case timeCreated = "time_created", timeUpdated = "time_updated"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        reviewerId = try values.decode(Int.self, forKey: .reviewerId)
        title = try values.decode(String.self, forKey: .title)
        content = try values.decode(String.self, forKey: .content)
        remark = try values.decode(Int.self, forKey: .remark)
        
//        let formatter = ISO8601DateFormatter()
//        formatter.formatOptions = [.withTimeZone,.withFractionalSeconds,.withInternetDateTime]
//        let timeCreatedStr = try values.decode(String.self, forKey: timeCreated)
        
        isMe = try values.decode(Bool.self, forKey: .isMe)
        vote = try values.decode(Int.self, forKey: .vote)
    }
}
