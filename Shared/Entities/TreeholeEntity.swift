import Foundation
import SwiftUI

struct THUser: Hashable, Codable, Identifiable {
    let id: Int
    let nickname: String
    let joinTime: Date
    var favorites: [Int]
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
    let color: Color // tag color for display, calculated during init
}

struct THFloor: Hashable, Codable, Identifiable {
    let id, holeId: Int
    let updateTime, createTime: Date
    let like: Int
    let liked: Bool?
    let isMe: Bool
    let deleted: Bool
    let storey: Int
    let content, posterName: String
    let mention: [THMention]
    
    let posterColor: Color // poster color for display, calculated during init
}

struct THMention: Hashable, Codable {
    let floorId, holeId: Int
    let content: String
    let posterName: String
    // TODO: time_updated, time_created, deleted, fold ([]), like, special_tag, storey
}

struct THHole: Hashable, Decodable, Identifiable {
    let id, divisionId: Int
    let view, reply: Int
    let updateTime, createTime: Date
    let tags: [THTag]
    let firstFloor, lastFloor: THFloor
    var floors: [THFloor]
}
