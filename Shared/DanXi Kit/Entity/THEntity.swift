import Foundation

struct THHole: Hashable, Decodable, Identifiable {
    let id, divisionId: Int
    let view, reply: Int
    var hidden: Bool
    let updateTime, createTime: Date
    let tags: [THTag]
    let firstFloor, lastFloor: THFloor
    var floors: [THFloor]
    
    var nsfw: Bool {
        for tag in tags {
            if tag.name.hasPrefix("*") {
                return true
            }
        }
        
        return false
    }
    
    var info: THHoleInfo {
        return THHoleInfo(holeId: id,
                          divisionId: divisionId,
                          tags: tags.map(\.name),
                          unhidden: !hidden,
                          locked: false) // TODO: locked
    }
    
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

struct THHoleInfo: Hashable, Codable {
    let holeId: Int
    var divisionId: Int
    var tags: [String]
    var unhidden: Bool
    var locked: Bool
}

struct THFloor: Hashable, Codable, Identifiable {
    let id, holeId: Int
    let updateTime, createTime: Date
    let like: Int
    let liked: Bool
    let isMe: Bool
    let deleted: Bool
    let modified: Int
    var storey: Int
    var content: String
    let posterName, spetialTag: String
    let mention: [THMention]
    
    let listId = UUID()
    
    func firstMention() -> Int? {
        let pattern = #/
            \#\#
            (?<id> \d+)
        /#
        if let result = content.firstMatch(of: pattern) {
            return Int(result.id)
        }
        return nil
    }
    
    func removeFirstMention() -> String {
        let pattern =  #/
            \#\#
            (?<id> \d+)
        /#
        return content.replacing(pattern, with: "", maxReplacements: 1)
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
        case modified, storey, content, spetialTag = "special_tag"
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

struct THMention: Hashable, Codable {
    let floorId, holeId: Int
    let content: String
    let posterName: String
    let createTime, updateTime: Date
    let deleted: Bool
    
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

struct THDivision: Hashable, Decodable, Identifiable {
    let id: Int
    let name, description: String
    let pinned: [THHole]
    
    enum CodingKeys: String, CodingKey {
        case id = "division_id"
        case name
        case description
        case pinned
    }
}

struct THTag: Hashable, Codable, Identifiable {
    let id, temperature: Int
    let name: String
    
    // FIXME: Delete this extension when backend temprature not exist bug is resolved.
    
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

struct THHistory: Hashable, Codable, Identifiable {
    let id: Int
    let userId: Int
    let floorId: Int
    let content: String
    let reason: String
    let createTime, updateTime: Date
    
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

struct THReport: Hashable, Codable, Identifiable {
    let id, holeId: Int
    var floor: THFloor
    let reason: String
    let createTime, updateTime: Date
    let dealt: Bool
    let dealtBy: Int?
    
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
