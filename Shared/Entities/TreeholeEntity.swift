import Foundation
import SwiftUI

struct THHole: Hashable, Decodable, Identifiable {
    let id, divisionId: Int
    let view, reply: Int
    let hidden: Bool
    let updateTime, createTime: Date
    let tags: [THTag]
    let firstFloor, lastFloor: THFloor
    var floors: [THFloor]
}

struct THFloor: Hashable, Codable, Identifiable {
    let id, holeId: Int
    let updateTime, createTime: Date
    let like: Int
    let liked: Bool
    let isMe: Bool
    let deleted: Bool
    let storey: Int
    // TODO: fold: [?]
    let content, posterName, spetialTag: String
    let mention: [THMention]
    let history: [THHistory]
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
    
    static let dummy = THDivision(id: 1, name: "树洞", description: "", pinned: [])
}

struct THTag: Hashable, Codable, Identifiable {
    let id, temperature: Int
    let name: String
}

struct THHistory: Hashable, Codable {
    let content: String
    let alteredBy: Int
    let alteredTime: Date
}

struct THUser: Hashable, Codable, Identifiable {
    let id: Int
    let nickname: String
    let joinTime: Date
    var favorites: [Int]
    let isAdmin: Bool
}
