import Foundation

struct THUser: Hashable, Codable, Identifiable {
    let id: Int
    let nickname: String
}

struct THDivision: Hashable, Decodable, Identifiable {
    let id: Int
    let name, description: String
    let pinned: [THHole]
    
    static let dummy = THDivision(id: 1, name: "树洞", description: "", pinned: [])
}

struct THTag: Hashable, Codable, Identifiable {
    let id, temperature: Int
    let name: String
}

struct THFloor: Hashable, Codable, Identifiable {
    let id, holeId: Int
    let iso8601UpdateTime, iso8601CreateTime: String
    let updateTime, createTime: Date
    let like: Int
    let liked: Bool?
    let storey: Int
    let content, posterName: String
}

struct THHole: Hashable, Decodable, Identifiable {
    let id, divisionId: Int
    let view, reply: Int
    let iso8601UpdateTime, iso8601CreateTime: String
    let updateTime, createTime: Date
    let tags: [THTag]
    let firstFloor, lastFloor: THFloor
    var floors: [THFloor]
}
