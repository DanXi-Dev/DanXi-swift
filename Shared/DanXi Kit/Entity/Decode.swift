import Foundation

// MARK: General

extension DXUser {
    enum CodingKeys: String, CodingKey {
        case id
        case nickname
        case joinTime = "joined_time"
        case isAdmin = "is_admin"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        nickname = try values.decode(String.self, forKey: .nickname)
        isAdmin = try values.decode(Bool.self, forKey: .isAdmin)
        self.joinTime = try decodeDate(values, key: .joinTime)
        self.banned = [:]
    }
}

extension DXInfo {
    enum CodingKeys: String, CodingKey {
        case id = "objectId"
        case content
        case type = "maxVersion"
    }
}

extension Timetable {
    enum CodingKeys: String, CodingKey {
        case semester = "id"
        case startDate
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let semesterString = try values.decode(String.self, forKey: .semester)
        guard let semester = Int(semesterString) else {
            throw ParseError.invalidJSON
        }
        self.semester = semester

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        guard let startDate = dateFormatter.date(from: try values.decode(String.self, forKey: .startDate)) else {
            throw ParseError.invalidDateFormat
        }
        self.startDate = startDate
    }
}

// MARK: Forum

extension THHole {
    enum CodingKeys: String, CodingKey {
        case id = "hole_id"
        case divisionId = "division_id"
        case view
        case reply
        case hidden
        case updateTime = "time_updated"
        case createTime = "time_created"
        case tags
        
        case floorStruct = "floors"
        enum FloorsKeys: String, CodingKey {
            case firstFloor = "first_floor"
            case lastFloor = "last_floor"
            case floors = "prefetch"
        }
    }
        
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        divisionId = try values.decode(Int.self, forKey: .divisionId)
        view = try values.decode(Int.self, forKey: .view)
        reply = try values.decode(Int.self, forKey: .reply)
        tags = try values.decode([THTag].self, forKey: .tags)
        hidden = try values.decode(Bool.self, forKey: .hidden)
        self.createTime = try decodeDate(values, key: .createTime)
        self.updateTime = try decodeDate(values, key: .updateTime)
        let floorStruct = try values.nestedContainer(keyedBy: CodingKeys.FloorsKeys.self, forKey: .floorStruct)
        firstFloor = try floorStruct.decode(THFloor.self, forKey: .firstFloor)
        lastFloor = try floorStruct.decode(THFloor.self, forKey: .lastFloor)
        floors = try floorStruct.decode([THFloor].self, forKey: .floors)
    }
}

extension THFloor {
    enum CodingKeys: String, CodingKey {
        case id = "floor_id"
        case updateTime = "time_updated"
        case createTime = "time_created"
        case like, liked, dislike, disliked
        case isMe = "is_me"
        case deleted
        case fold = "fold_v2"
        case holeId = "hole_id"
        case modified, storey, content, spetialTag = "special_tag"
        case posterName = "anonyname"
        case mention
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        like = try values.decode(Int.self, forKey: .like)
        liked = try values.decodeIfPresent(Bool.self, forKey: .liked) ?? false
        dislike = try values.decode(Int.self, forKey: .dislike)
        disliked = try values.decodeIfPresent(Bool.self, forKey: .disliked) ?? false
        isMe = try values.decodeIfPresent(Bool.self, forKey: .isMe) ?? false
        deleted = try values.decodeIfPresent(Bool.self, forKey: .deleted) ?? false
        fold = try values.decode(String.self, forKey: .fold)
        holeId = try values.decode(Int.self, forKey: .holeId)
        modified = try values.decode(Int.self, forKey: .modified)
        storey = try values.decodeIfPresent(Int.self, forKey: .storey) ?? 0
        content = try values.decode(String.self, forKey: .content)
        spetialTag = try values.decode(String.self, forKey: .spetialTag)
        let posterName = try values.decode(String.self, forKey: .posterName)
        self.posterName = posterName
        self.createTime = try decodeDate(values, key: .createTime)
        self.updateTime = try decodeDate(values, key: .updateTime)
        mention = try values.decodeIfPresent([THMention].self, forKey: .mention) ?? []
    }
}

extension THMention {
    enum CodingKeys: String, CodingKey {
        case floorId = "floor_id"
        case holeId = "hole_id"
        case content
        case posterName = "anonyname"
        case createTime = "time_created"
        case updateTime = "time_updated"
        case deleted
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        floorId = try values.decode(Int.self, forKey: .floorId)
        holeId = try values.decode(Int.self, forKey: .holeId)
        content = try values.decode(String.self, forKey: .content)
        posterName = try values.decode(String.self, forKey: .posterName)
        deleted = try values.decode(Bool.self, forKey: .deleted)
        self.createTime = try decodeDate(values, key: .createTime)
        self.updateTime = try decodeDate(values, key: .updateTime)
    }
}

extension THDivision {
    enum CodingKeys: String, CodingKey {
        case id = "division_id"
        case name
        case description
        case pinned
    }
}

extension THTag {
    enum CodingKeys: String, CodingKey {
        case id
        case name, temperature
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        let nameStr = try values.decode(String.self, forKey: .name)
        name = nameStr
        temperature = try values.decodeIfPresent(Int.self, forKey: .temperature) ?? 0
    }
}

extension THHistory {
    enum CodingKeys: String, CodingKey {
        case content, id, reason
        case floorId = "floor_id"
        case userId = "user_id"
        case createTime = "time_created"
        case updateTime = "time_updated"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        userId = try values.decode(Int.self, forKey: .userId)
        floorId = try values.decode(Int.self, forKey: .floorId)
        content = try values.decode(String.self, forKey: .content)
        reason = try values.decode(String.self, forKey: .reason)
        createTime = try decodeDate(values, key: .createTime)
        updateTime = try decodeDate(values, key: .updateTime)
    }
}

extension THReport {
    enum CodingKeys: String, CodingKey {
        case id
        case holeId = "hole_id"
        case floor
        case reason
        case createTime = "time_created"
        case updateTime = "time_updated"
        case dealt
        case dealtBy = "dealt_by"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        holeId = try values.decode(Int.self, forKey: .holeId)
        reason = try values.decode(String.self, forKey: .reason)
        dealt = try values.decode(Bool.self, forKey: .dealt)
        dealtBy = try values.decode(Int?.self, forKey: .dealtBy)
        self.createTime = try decodeDate(values, key: .createTime)
        self.updateTime = try decodeDate(values, key: .updateTime)
        floor = try values.decode(THFloor.self, forKey: .floor)
    }
}

extension THMessage {
    enum CodingKeys: String, CodingKey {
        case id, data, description, code
        case createTime = "time_created"
        case updateTime = "time_updated"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(Int.self, forKey: .id)
        self.description = try values.decode(String.self, forKey: .description)
        self.createTime = try decodeDate(values, key: .createTime)
        self.updateTime = try decodeDate(values, key: .updateTime)
        let code = THMessageType(rawValue: try values.decode(String.self, forKey: .code)) ?? .message
        self.code = code
        switch code {
        case .favorite, .reply, .mention, .modify, .permission:
            self.floor = try values.decode(THFloor.self, forKey: .data)
            self.report = nil
        case .report, .reportDealt:
            self.floor = nil
            self.report = try values.decode(THReport.self, forKey: .data)
        default:
            self.floor = nil
            self.report = nil
        }
    }
}

// MARK: Curriculum

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
