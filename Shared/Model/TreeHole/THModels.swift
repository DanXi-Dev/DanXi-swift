import Foundation

struct THUser: Hashable, Codable, Identifiable {
    let id: Int
    let nickname: String
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

struct THFloor: Hashable, Codable, Identifiable {
    let id, holeId: Int
    let updateTime, createTime: String
    let like: Int
    let liked: Bool?
    let storey: Int
    let content, poster: String
}

struct THHole: Hashable, Decodable, Identifiable {
    let id, divisionId: Int
    let view, reply: Int
    let updateTime, createTime: String
    let tags: [THTag]
    let firstFloor, lastFloor: THFloor
    var floors: [THFloor]
}
