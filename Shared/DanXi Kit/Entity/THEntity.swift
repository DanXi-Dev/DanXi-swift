import Foundation

struct THHole: Hashable, Identifiable, Decodable {
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
}

struct THHoleInfo: Hashable, Codable {
    let holeId: Int
    var divisionId: Int
    var tags: [Tag]
    var unhidden: Bool
    var locked: Bool // TODO: update THHole
    
    struct Tag: Hashable, Codable {
        let name: String
    }
    
    init(_ hole: THHole) {
        self.holeId = hole.id
        self.divisionId = hole.divisionId
        self.tags = []
        self.unhidden = !hole.hidden
        self.locked = false // TODO: update THHole
    }
    
    mutating func setTags(_ tags: [String]) {
        self.tags = tags.map { Tag(name: $0) }
    }
}

struct THFloor: Hashable, Codable, Identifiable {
    let id, holeId: Int
    let updateTime, createTime: Date
    let like, dislike: Int
    let liked, disliked: Bool
    let isMe: Bool
    let deleted: Bool
    let fold: String
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

struct THMention: Hashable, Codable {
    let floorId, holeId: Int
    let content: String
    let posterName: String
    let createTime, updateTime: Date
    let deleted: Bool
}

struct THDivision: Hashable, Decodable, Identifiable {
    let id: Int
    let name, description: String
    let pinned: [THHole]
}

struct THTag: Hashable, Codable, Identifiable {
    let id, temperature: Int
    let name: String
}

struct THHistory: Hashable, Codable, Identifiable {
    let id: Int
    let userId: Int
    let floorId: Int
    let content: String
    let reason: String
    let createTime, updateTime: Date
}

struct THReport: Hashable, Codable, Identifiable {
    let id, holeId: Int
    var floor: THFloor
    let reason: String
    let createTime, updateTime: Date
    let dealt: Bool
    let dealtBy: Int?
}
