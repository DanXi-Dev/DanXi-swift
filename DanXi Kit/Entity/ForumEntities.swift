import Foundation

public struct Division: Identifiable, Codable, Hashable {
    public let id: Int
    public let name, description: String
    public let pinned: [Hole]
}

public struct Hole: Identifiable, Codable, Hashable {
    public let id: Int
    public let timeCreated, timeUpdated: Date
    public let divisionId: Int
    public let view, reply, favoriteCount, subscriptionCount: Int
    public let locked: Bool
    public let hidden: Bool
    public let frozen: Bool
    public let tags: [Tag]
    public let firstFloor, lastFloor: Floor
    public let prefetch: [Floor]
}

public struct Floor: Identifiable, Codable, Hashable {
    public let id: Int
    public let holeId: Int
    public let timeCreated, timeUpdated: Date
    public let anonyname: String
    public let specialTag: String
    public let content: String
    public let like, dislike: Int
    public let liked, disliked: Bool
    public let isMe: Bool
    public let modified, deleted: Bool
    public let fold: String
    public let mentions: [Mention]
    public let machineReviewedSensitive: Bool
    public let humanReviewedSensitive: Bool?
    public let sensitiveReason: String?
}

public struct FloorHistory: Identifiable, Codable, Hashable {
    public let id: Int
    public let floorId: Int
    public let timeCreated, timeUpdated: Date
    public let content: String
    public let reason: String
    public let userId: Int
}

public struct Mention: Codable, Hashable {
    public let floorId, holeId: Int
    public let anonyname: String
    public let content: String
    public let timeCreated, timeUpdated: Date
    public let deleted: Bool
}

public struct Tag: Identifiable, Codable, Hashable {
    public let id: Int
    public let temperature: Int
    public let name: String
}

public struct Report: Identifiable, Hashable, Codable {
    public let id: Int
    public let timeCreated, timeUpdated: Date
    public let holeId: Int
    public let floor: Floor
    public let reason: String
    public let dealt: Bool
    public let dealtBy: Int?
}

public struct Sensitive: Identifiable, Hashable, Codable {
    public let id: Int
    public let holeId: Int
    public let content: String
    public let timeCreated, timeUpdated: Date
    public let deleted: Bool
    public let modified: Bool
    public let sensitive: Bool?
    public let sensitiveDetail: String?
}

public struct Message: Identifiable, Hashable, Decodable {
    public let id: Int
    public let timeCreated, timeUpdated: Date
    public let description: String
    public let type: MessageType
    public let floor: Floor?
    public let report: Report?
}

public enum MessageType: String, Codable {
    case favorite, reply, mention, modify, permission, report, reportDealt = "report_dealt", mail
}

public struct Profile: Identifiable, Hashable, Decodable {
    public let id: Int
    public let nickname: String
    public let joinTime: Date
    public let isAdmin: Bool
    public let answeredQuestions: Bool
    public let bannedDivision: [Int: Date]
    public let notificationConfiguration: [String]
    public let showFoldedConfiguration: String
}
