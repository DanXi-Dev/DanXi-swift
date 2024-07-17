import Foundation

extension CourseGroup {
    enum CodingKeys: String, CodingKey {
        case id, name, code, department
        case campusName
        case courseList
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        code = try values.decode(String.self, forKey: .code)
        department = try values.decode(String.self, forKey: .department)
        campus = try values.decode(String.self, forKey: .campusName)
        courses = try values.decode([Course].self, forKey: .courseList)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(code, forKey: .code)
        try container.encode(department, forKey: .department)
        try container.encode(campus, forKey: .campusName)
        try container.encode(courses, forKey: .courseList)
    }
}

extension Course {
    enum CodingKeys: String, CodingKey {
        case id, name, code, department, teachers, year, semester, credit
        case codeId
        case campusName
        case maxStudent
        case weekHour
        case reviewList
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        code = try values.decode(String.self, forKey: .code)
        codeId = try values.decode(String.self, forKey: .codeId)
        department = try values.decode(String.self, forKey: .department)
        campus = try values.decode(String.self, forKey: .campusName)
        teachers = try values.decode(String.self, forKey: .teachers)
        maxStudent = try values.decode(Int.self, forKey: .maxStudent)
        weekHour = try values.decode(Int.self, forKey: .weekHour)
        year = try values.decode(Int.self, forKey: .year)
        semester = try values.decode(Int.self, forKey: .semester)
        credit = try values.decodeIfPresent(Double.self, forKey: .credit) ?? 0
        reviews = try values.decodeIfPresent([Review].self, forKey: .reviewList) ?? []
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(code, forKey: .code)
        try container.encode(codeId, forKey: .codeId)
        try container.encode(department, forKey: .department)
        try container.encode(campus, forKey: .campusName)
        try container.encode(teachers, forKey: .teachers)
        try container.encode(maxStudent, forKey: .maxStudent)
        try container.encode(weekHour, forKey: .weekHour)
        try container.encode(year, forKey: .year)
        try container.encode(semester, forKey: .semester)
        try container.encode(credit, forKey: .credit)
        try container.encode(reviews, forKey: .reviewList)
    }
}

extension CurriculumSensitive {
    enum CodingKeys: String, CodingKey {
        case id, title, content, timeCreated, timeUpdated
        case isSensitive
        case isActualSensitive
        case sensitiveDetail
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try values.decode(Int.self, forKey: .id)
        title = try values.decode(String.self, forKey: .title)
        content = try values.decode(String.self, forKey: .content)
        timeCreated = try values.decode(Date.self, forKey: .timeCreated)
        timeUpdated = try values.decode(Date.self, forKey: .timeUpdated)
        
        humanReviewedSensitive = try values.decodeIfPresent(Bool.self, forKey: .isActualSensitive)
        sensitiveReason = try values.decodeIfPresent(String.self, forKey: .sensitiveDetail)
    }
}
