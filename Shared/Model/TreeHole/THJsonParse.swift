import Foundation

// 解析树洞服务器返回的JSON数据

extension OTFloor {
    enum CodingKeys: String, CodingKey {
        case id = "floor_id"
        case updateTime = "time_updated"
        case createTime = "time_created"
        case like
        case liked
        case holeId = "hole_id"
        case storey, content
        case poster = "anonyname"
    }
}

extension OTUser {
    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case nickname
    }
}

extension OTDivision {
    enum CodingKeys: String, CodingKey {
        case id = "division_id"
        case name
        case description
        case pinned
    }
}

extension OTTag {
    enum CodingKeys: String, CodingKey {
        case id = "tag_id"
        case name, temperature
    }
}

extension OTHole {
    enum CodingKeys: String, CodingKey {
        case id = "hole_id"
        case divisionId = "division_id"
        case view
        case reply
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
        updateTime = try values.decode(String.self, forKey: .updateTime)
        createTime = try values.decode(String.self, forKey: .createTime)
        tags = try values.decode([OTTag].self, forKey: .tags)
        
        let floorStruct = try values.nestedContainer(keyedBy: CodingKeys.FloorsKeys.self, forKey: .floorStruct)
        firstFloor = try floorStruct.decode(OTFloor.self, forKey: .firstFloor)
        lastFloor = try floorStruct.decode(OTFloor.self, forKey: .lastFloor)
        floors = try floorStruct.decode([OTFloor].self, forKey: .floors)
    }
}
