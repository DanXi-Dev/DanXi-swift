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
        // FIXME: temporary measure, wait for backend API to update.
#if DEBUG
        isAdmin = true
#else
        isAdmin = try values.decode(Bool.self, forKey: .isAdmin)
#endif
        self.joinTime = try decodeDate(values, key: .joinTime)
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
