import Foundation

extension THFloor {
    enum CodingKeys: String, CodingKey {
        case id = "floor_id"
        case iso8601UpdateTime = "time_updated"
        case iso8601CreateTime = "time_created"
        case like
        case liked
        case holeId = "hole_id"
        case storey, content
        case posterName = "anonyname"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        like = try values.decode(Int.self, forKey: .like)
        liked = try values.decodeIfPresent(Bool.self, forKey: .liked)
        holeId = try values.decode(Int.self, forKey: .holeId)
        storey = try values.decode(Int.self, forKey: .storey)
        content = try values.decode(String.self, forKey: .content)
        posterName = try values.decode(String.self, forKey: .posterName)
        iso8601UpdateTime = try values.decode(String.self, forKey: .iso8601UpdateTime)
        iso8601CreateTime = try values.decode(String.self, forKey: .iso8601CreateTime)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withTimeZone,.withFractionalSeconds,.withInternetDateTime]
        if let ut = formatter.date(from: iso8601UpdateTime), let ct = formatter.date(from: iso8601CreateTime) {
            updateTime = ut
            createTime = ct
        } else {
            throw TreeholeError.invalidFormat(reason: "Invalid ISO8601 Date")
        }
    }
}

extension THUser {
    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case nickname
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
        case id = "tag_id"
        case name, temperature
    }
}

extension THHole {
    enum CodingKeys: String, CodingKey {
        case id = "hole_id"
        case divisionId = "division_id"
        case view
        case reply
        case iso8601UpdateTime = "time_updated"
        case iso8601CreateTime = "time_created"
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
        iso8601UpdateTime = try values.decode(String.self, forKey: .iso8601UpdateTime)
        iso8601CreateTime = try values.decode(String.self, forKey: .iso8601CreateTime)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withTimeZone,.withFractionalSeconds,.withInternetDateTime]
        if let ut = formatter.date(from: iso8601UpdateTime), let ct = formatter.date(from: iso8601CreateTime) {
            updateTime = ut
            createTime = ct
        } else {
            throw TreeholeError.invalidFormat(reason: "Invalid ISO8601 Date")
        }
        
        let floorStruct = try values.nestedContainer(keyedBy: CodingKeys.FloorsKeys.self, forKey: .floorStruct)
        firstFloor = try floorStruct.decode(THFloor.self, forKey: .firstFloor)
        lastFloor = try floorStruct.decode(THFloor.self, forKey: .lastFloor)
        floors = try floorStruct.decode([THFloor].self, forKey: .floors)
    }
}
