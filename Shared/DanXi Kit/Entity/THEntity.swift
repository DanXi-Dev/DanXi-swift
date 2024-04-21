import Foundation

struct THHole: Hashable, Identifiable, Decodable {
    let id, divisionId: Int
    let view, reply: Int
    var hidden: Bool
    var locked: Bool
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
    var lock: Bool
    
    struct Tag: Hashable, Codable {
        let name: String
    }
    
    init(_ hole: THHole) {
        self.holeId = hole.id
        self.divisionId = hole.divisionId
        self.tags = []
        self.unhidden = !hole.hidden
        self.lock = hole.locked
    }
    
    mutating func setTags(_ tags: [String]) {
        self.tags = tags.map { Tag(name: $0) }
    }
}

struct THBrowseHistory: Identifiable, Hashable, Codable {
    let id: Int
    let view, reply: Int
    let tags: [THTag]
    let content: String
    let browseTime: Date
    
    init(_ hole: THHole) {
        self.id = hole.id
        self.view = hole.view
        self.reply = hole.reply
        self.tags = hole.tags
        self.content = hole.firstFloor.content
        self.browseTime = Date.now
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
    var mention: [THMention]
    let sensitiveDetail: String?
    
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
    let sensitiveDetail: String?
}

struct THReport: Hashable, Codable, Identifiable {
    let id, holeId: Int
    var floor: THFloor
    let reason: String
    let createTime, updateTime: Date
    let dealt: Bool
    let dealtBy: Int?
}

struct THMessage: Hashable, Decodable, Identifiable {
    let id: Int
    let description: String
    let createTime, updateTime: Date
    let code: THMessageType
    
    let floor: THFloor?
    let report: THReport?
}

enum THMessageType: String {
    case favorite, reply, mention, modify, permission, report, reportDealt = "report_dealt", mail
    case message // reserved for match failure
}

struct THSensitiveEntry: Identifiable, Codable, Hashable {
    let id: Int
    let holeId: Int
    let content: String
    let deleted: Bool
    let modified: Int
    let sensitive: Bool?
    let createTime, updateTime: Date
}
