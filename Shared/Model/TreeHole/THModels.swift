import Foundation

struct OTUser: Hashable, Codable, Identifiable {
    let id: Int
    let nickname: String
}

struct OTDivision: Hashable, Decodable, Identifiable {
    let id: Int
    let name, description: String
    let pinned: [OTHole]
}

struct OTTag: Hashable, Codable, Identifiable {
    let id, temperature: Int
    let name: String
}

struct OTFloor: Hashable, Codable, Identifiable {
    let id, holeId: Int
    let updateTime, createTime: String
    let like: Int
    let liked: Bool?
    let storey: Int
    let content, poster: String
}

struct OTHole: Hashable, Decodable, Identifiable {
    let id, divisionId: Int
    let view, reply: Int
    let updateTime, createTime: String
    let tags: [OTTag]
    let firstFloor, lastFloor: OTFloor
    var floors: [OTFloor]
}
