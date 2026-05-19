import Foundation

public enum DantaIntelligenceSession {
    public static let newSessionKey = "new"
    
    public static func isNew(_ sessionKey: String) -> Bool {
        sessionKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == newSessionKey
    }
}

public enum DantaIntelligenceRole: String, Codable, Sendable {
    case user
    case assistant
    case openclaw
    case mockOpenClaw = "mock_openclaw"
    case claw
    case server
    case client
    
    var openClawRole: String {
        switch self {
        case .user, .client:
            "user"
        case .assistant, .openclaw, .mockOpenClaw, .claw, .server:
            "assistant"
        }
    }
}

public struct DantaIntelligenceChannel: Codable, Identifiable, Sendable {
    public let userSessionId: Int
    public let createdAt: Date
    public let updatedAt: Date
    
    public var id: Int { userSessionId }
}

public struct DantaIntelligenceMessage: Codable, Identifiable, Sendable {
    public let type: String
    public let from: DantaIntelligenceRole
    public let content: String
    public let messageId: String
    public let channelId: Int
    public let timestamp: Int64
    public let media: AnyCodable?
    public let version: String?
    
    public var id: String { messageId }
}

struct DantaIntelligenceSocketEnvelope: Codable, Sendable {
    let type: String
}

struct DantaIntelligenceAuthRequest: Codable, Sendable {
    let type = "auth"
    let token: String
    let timestamp: Int64
    let version: String
}

struct DantaIntelligenceAuthSuccess: Codable, Sendable {
    let type: String
    let timestamp: Int64?
    let channelCount: Int
    let version: String?
}

struct DantaIntelligenceErrorMessage: Codable, Sendable {
    let type: String
    let code: String?
    let errorMessage: String?
    let messageId: String?
    let channelId: Int?
    let timestamp: Int64?
}

struct DantaIntelligenceSocketMessage: Codable, Sendable {
    let type: String
    let from: DantaIntelligenceRole
    let content: String
    let messageId: String
    let channelId: Int
    let timestamp: Int64
    let media: AnyCodable?
    let version: String?
}

struct DantaIntelligencePing: Codable, Sendable {
    let type: String
    let timestamp: Int64?
    let version: String?
}

struct DantaIntelligencePong: Codable, Sendable {
    let type = "pong"
    let timestamp: Int64
    let version: String
}

extension DantaIntelligenceMessage {
    var openClawMessage: OpenClawChatMessage {
        OpenClawChatMessage(
            role: from.openClawRole,
            content: [
                OpenClawChatMessageContent(
                    type: "text",
                    text: content,
                    thinking: nil,
                    thinkingSignature: nil,
                    mimeType: nil,
                    fileName: nil,
                    content: nil)
            ],
            timestamp: Double(timestamp))
    }
}

extension DantaIntelligenceSocketMessage {
    var openClawMessage: OpenClawChatMessage {
        OpenClawChatMessage(
            role: from.openClawRole,
            content: [
                OpenClawChatMessageContent(
                    type: "text",
                    text: content,
                    thinking: nil,
                    thinkingSignature: nil,
                    mimeType: nil,
                    fileName: nil,
                    content: nil)
            ],
            timestamp: Double(timestamp))
    }
}

extension OpenClawChatMessage {
    public var dantaPrimaryText: String {
        content.compactMap(\.text).joined(separator: "\n")
    }
}

extension Int64 {
    static var dantaNowMilliseconds: Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }
}
