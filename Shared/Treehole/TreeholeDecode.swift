import Foundation
import SwiftUI

extension THFloor {
    enum CodingKeys: String, CodingKey {
        case id = "floor_id"
        case iso8601UpdateTime = "time_updated"
        case iso8601CreateTime = "time_created"
        case like
        case liked
        case isMe = "is_me"
        case deleted
        case holeId = "hole_id"
        case storey, content
        case posterName = "anonyname"
        case mention
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        like = try values.decode(Int.self, forKey: .like)
        liked = try values.decodeIfPresent(Bool.self, forKey: .liked)
        isMe = try values.decodeIfPresent(Bool.self, forKey: .isMe) ?? false
        deleted = try values.decodeIfPresent(Bool.self, forKey: .deleted) ?? false
        holeId = try values.decode(Int.self, forKey: .holeId)
        storey = try values.decode(Int.self, forKey: .storey)
        content = try values.decode(String.self, forKey: .content)
        let posterName = try values.decode(String.self, forKey: .posterName)
        self.posterName = posterName
        iso8601UpdateTime = try values.decode(String.self, forKey: .iso8601UpdateTime)
        iso8601CreateTime = try values.decode(String.self, forKey: .iso8601CreateTime)
        mention = try values.decodeIfPresent([THMention].self, forKey: .mention) ?? []
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withTimeZone,.withFractionalSeconds,.withInternetDateTime]
        if let ut = formatter.date(from: iso8601UpdateTime), let ct = formatter.date(from: iso8601CreateTime) {
            updateTime = ut
            createTime = ct
        } else {
            throw TreeholeError.invalidFormat(reason: "Invalid ISO8601 Date")
        }
        
        self.posterColor = randomColor(name: posterName)
    }
}

extension THMention {
    enum CodingKeys: String, CodingKey {
        case floorId = "floor_id"
        case holeId = "hole_id"
        case content
        case posterName = "anonyname"
    }
}

extension THUser {
    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case nickname
        case favorites
        case joinTime = "joined_time"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        nickname = try values.decode(String.self, forKey: .nickname)
        favorites = try values.decode([Int].self, forKey: .favorites)
        let iso8601JoinTime = try values.decode(String.self, forKey: .joinTime)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withTimeZone,.withFractionalSeconds,.withInternetDateTime]
        if let time = formatter.date(from: iso8601JoinTime) {
            joinTime = time
        } else {
            throw TreeholeError.invalidFormat(reason: "Invalid ISO8601 Date")
        }
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
    
    init(id: Int, temperature: Int, name: String) {
        self.id = id
        self.temperature = temperature
        self.name = name
        self.color = randomColor(name: name)
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        let nameStr = try values.decode(String.self, forKey: .name)
        name = nameStr
        temperature = try values.decode(Int.self, forKey: .temperature)
        
        color = randomColor(name: name)
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
