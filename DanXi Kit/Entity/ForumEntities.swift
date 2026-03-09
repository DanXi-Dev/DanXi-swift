import Foundation
import Utils

public struct Division: Identifiable, Codable, Hashable {
    public let id: Int
    public let name, description: String
    public let pinned: [Hole]
}

public struct Hole: Identifiable, Codable, Hashable {
    public let id: Int
    public let timeCreated, timeUpdated: Date
    public let timeDeleted: Date?
    public let divisionId: Int
    public let view, reply, favoriteCount, subscriptionCount: Int
    public let locked: Bool
    public let hidden: Bool
    public let frozen: Bool
    public let aiSummaryAvailable: Bool
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
    
    public var highlight: Bool {
        return ConfigurationCenter.configuration.highlightTagIds.contains(id)
    }
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

public struct AISummaryResponse: Codable{
    public let code: Int
    public let message: String
    public let data: AISummaryContent?
    
    enum CodingKeys: String, CodingKey {
            case code, message, data
        }
        
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.code = try container.decode(Int.self, forKey: .code)
        self.message = try container.decode(String.self, forKey: .message)
        
        if self.code == 1000 || self.code == 1001 {
            self.data = try container.decode(AISummaryContent.self, forKey: .data)
        } else {
            self.data = nil
        }
    }
}

public struct AISummaryContent: Codable{
    public let holeId: Int
    public let traceId: String?
    public let summary: String
    public let branches: [Branch]?
    public let interactions: [Interaction]?
    public let keywords: [String]?
    public let generatedAt: Date
    
    public static var placeholder: AISummaryContent {
        AISummaryContent(
            holeId: 0,
            traceId: "",
            summary: "AI is analyzing the conversation and generating a comprehensive summary for you. This may take a few seconds...",
            branches: [
                Branch(id: 1, label: "Main Topic", content: "The main discussion point of this thread.", color: "#007AFF", representativeFloors: []),
                Branch(id: 2, label: "Different Perspectives", content: "Various opinions shared by users.", color: "#5856D6", representativeFloors: [])
            ],
            interactions: [],
            keywords: ["Analyzing", "Summarizing", "AI"],
            generatedAt: Date()
        )
    }

    public struct Branch: Codable, Hashable {
        public let id: Int
        public let label: String
        public let content: String
        public let color: String
        public let representativeFloors: [Int]
    }
    
    public struct Interaction: Codable, Hashable {
        public let fromFloor: Int
        public let fromUser: String
        public let toFloor: Int
        public let toUser: String
        public let interactionType: InteractionType
        public let content: String
        
        public enum InteractionType: String, Codable, Hashable {
            case support
            case question
            case reply
            case rebuttal
            case supplement
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let rawValue = try container.decode(String.self)
                self = InteractionType(rawValue: rawValue) ?? .reply
            }
        }
    }
}
