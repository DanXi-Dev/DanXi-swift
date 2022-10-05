import Foundation
import SwiftUI

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
        let iso8601UpdateTime = try values.decode(String.self, forKey: .updateTime)
        let iso8601CreateTime = try values.decode(String.self, forKey: .createTime)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withTimeZone,.withFractionalSeconds,.withInternetDateTime]
        if let updateTime = formatter.date(from: iso8601UpdateTime), let createTime = formatter.date(from: iso8601CreateTime) {
            self.updateTime = updateTime
            self.createTime = createTime
        } else {
            throw NetworkError.invalidResponse
        }
        
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
        case like
        case liked
        case isMe = "is_me"
        case deleted
        case holeId = "hole_id"
        case storey, content, spetialTag = "special_tag"
        case posterName = "anonyname"
        case mention
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        like = try values.decode(Int.self, forKey: .like)
        liked = try values.decodeIfPresent(Bool.self, forKey: .liked) ?? false
        isMe = try values.decodeIfPresent(Bool.self, forKey: .isMe) ?? false
        deleted = try values.decodeIfPresent(Bool.self, forKey: .deleted) ?? false
        holeId = try values.decode(Int.self, forKey: .holeId)
        storey = try values.decode(Int.self, forKey: .storey)
        content = try values.decode(String.self, forKey: .content)
        spetialTag = try values.decode(String.self, forKey: .spetialTag)
        let posterName = try values.decode(String.self, forKey: .posterName)
        self.posterName = posterName
        
        let iso8601UpdateTime = try values.decode(String.self, forKey: .updateTime)
        let iso8601CreateTime = try values.decode(String.self, forKey: .createTime)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withTimeZone,.withFractionalSeconds,.withInternetDateTime]
        if let createTime = formatter.date(from: iso8601CreateTime),
           let updateTime = formatter.date(from: iso8601UpdateTime) {
            self.createTime = createTime
            self.updateTime = updateTime
        } else {
            throw NetworkError.invalidResponse
        }
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
        
        let iso8601UpdateTime = try values.decode(String.self, forKey: .updateTime)
        let iso8601CreateTime = try values.decode(String.self, forKey: .createTime)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withTimeZone,.withFractionalSeconds,.withInternetDateTime]
        if let createTime = formatter.date(from: iso8601CreateTime),
           let updateTime = formatter.date(from: iso8601UpdateTime) {
            self.createTime = createTime
            self.updateTime = updateTime
        } else {
            throw NetworkError.invalidResponse
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

// FIXME: Delete this extension when backend temprature not exist bug is resolved.
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
    }
}

extension DXUser {
    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case nickname
        case favorites
        case joinTime = "joined_time"
        case isAdmin = "is_admin"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        nickname = try values.decode(String.self, forKey: .nickname)
        favorites = try values.decode([Int].self, forKey: .favorites)
        isAdmin = try values.decode(Bool.self, forKey: .isAdmin)
        
        let iso8601JoinTime = try values.decode(String.self, forKey: .joinTime)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withTimeZone,.withFractionalSeconds,.withInternetDateTime]
        if let time = formatter.date(from: iso8601JoinTime) {
            joinTime = time
        } else {
            throw NetworkError.invalidResponse
        }
    }
}

extension THReport {
    enum CodingKeys: String, CodingKey {
        case id = "report_id"
        case holeId = "hole_id"
        case floor
        case reason
        case createTime = "time_created"
        case updateTime = "time_updated"
        case dealed
        case dealedBy = "dealed_by"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        holeId = try values.decode(Int.self, forKey: .holeId)
        floor = try values.decode(THFloor.self, forKey: .floor)
        reason = try values.decode(String.self, forKey: .reason)
        dealed = try values.decode(Bool.self, forKey: .dealed)
        dealedBy = try values.decode(Int?.self, forKey: .dealedBy)
        
        let iso8601UpdateTime = try values.decode(String.self, forKey: .updateTime)
        let iso8601CreateTime = try values.decode(String.self, forKey: .createTime)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withTimeZone,.withFractionalSeconds,.withInternetDateTime]
        if let createTime = formatter.date(from: iso8601CreateTime),
           let updateTime = formatter.date(from: iso8601UpdateTime) {
            self.createTime = createTime
            self.updateTime = updateTime
        } else {
            throw NetworkError.invalidResponse
        }
    }
}
