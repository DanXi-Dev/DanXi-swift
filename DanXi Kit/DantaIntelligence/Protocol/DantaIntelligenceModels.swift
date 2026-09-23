import Foundation

public enum DantaIntelligenceInstanceState: Hashable, Sendable {
    case notStarted
    case provisioning
    case starting
    case ready
    case stopping
    case stopped
    case resetting
    case failed
    case unknown(String)

    public init(rawValue: String) {
        switch rawValue {
        case "not_started": self = .notStarted
        case "provisioning": self = .provisioning
        case "starting": self = .starting
        case "ready": self = .ready
        case "stopping": self = .stopping
        case "stopped": self = .stopped
        case "resetting": self = .resetting
        case "failed": self = .failed
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .notStarted: "not_started"
        case .provisioning: "provisioning"
        case .starting: "starting"
        case .ready: "ready"
        case .stopping: "stopping"
        case .stopped: "stopped"
        case .resetting: "resetting"
        case .failed: "failed"
        case .unknown(let value): value
        }
    }

    public var isReady: Bool {
        self == .ready
    }

    public var isTransitioning: Bool {
        switch self {
        case .provisioning, .starting, .stopping, .resetting: true
        default: false
        }
    }
}

extension DantaIntelligenceInstanceState: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(String.self))
    }

}

public struct DantaIntelligenceInstanceStatus: Decodable, Sendable {
    public let instanceId: Int?
    public let state: DantaIntelligenceInstanceState
    public let lastErrorCode: String?
    public let lastErrorMessage: String?
    public let cleanupErrorCode: String?
    public let cleanupErrorMessage: String?
}

struct DantaIntelligenceOnboardPayload: Encodable, Sendable {
    let provider = "fleet"
    let name = ""
    let image = ""
    let metadata: [String: String] = [:]
}

public enum DantaIntelligenceLifecycleAction: String, Sendable {
    case start
    case stop
    case restart
    case reset
}

public struct DantaIntelligenceLifecycleOperation: Decodable, Sendable {
    public let status: String
}

public struct DantaIntelligenceLifecycleReadiness: Decodable, Sendable {
    public let containerRunning: Bool
    public let gatewayHealthy: Bool
    public let channelAuthenticated: Bool

    private enum CodingKeys: String, CodingKey {
        case containerRunning = "ContainerRunning"
        case gatewayHealthy = "GatewayHealthy"
        case channelAuthenticated = "ChannelAuthenticated"
    }
}

public struct DantaIntelligenceLifecycleResult: Decodable, Sendable {
    public let operation: DantaIntelligenceLifecycleOperation
    public let readiness: DantaIntelligenceLifecycleReadiness

    private enum CodingKeys: String, CodingKey {
        case operation = "Operation"
        case readiness = "Readiness"
    }
}

public enum DantaIntelligenceRole: String, Decodable, Sendable {
    case user
    case assistant
    case openclaw
    case mockOpenClaw = "mock_openclaw"
    case claw
    case server
    case client

    public var isUser: Bool {
        self == .user || self == .client
    }
}

public struct DantaIntelligenceChannel: Decodable, Identifiable, Sendable {
    public let userSessionId: Int
    public let conversation: String?
    public let updatedAt: Date

    public var id: Int { userSessionId }

    public var title: String {
        let title = conversation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return title.isEmpty
            ? String(localized: "Danta Intelligence Session \(userSessionId)", bundle: .module)
            : title
    }
}

public struct DantaIntelligenceMessage: Decodable, Identifiable, Sendable {
    public let from: DantaIntelligenceRole
    public let content: String
    public let messageId: String
    public let taskId: String?
    public let channelId: Int
    public let timestamp: Int64

    public var id: String {
        guard messageId.isEmpty else { return messageId }
        // Replies may have an empty message_id; task_id is stable across push and history.
        let key = taskId.flatMap { $0.isEmpty ? nil : $0 } ?? String(timestamp)
        return "\(channelId):\(from.rawValue):\(key)"
    }

    public init(from: DantaIntelligenceRole, content: String, messageId: String,
                taskId: String? = nil, channelId: Int, timestamp: Int64) {
        self.from = from
        self.content = content
        self.messageId = messageId
        self.taskId = taskId
        self.channelId = channelId
        self.timestamp = timestamp
    }
}

struct DantaIntelligenceSocketEnvelope: Decodable, Sendable {
    let type: String
    let requestId: String?
}

struct DantaIntelligenceAuthRequest: Encodable, Sendable {
    let type = "auth"
    let token: String
    let version = "1.0"
}

struct DantaIntelligenceErrorMessage: Decodable, Sendable {
    let requestId: String?
    let errorCode: String?
    let message: String?

    private enum CodingKeys: String, CodingKey {
        case requestId, errorCode, code, message, errorMessage
    }

    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        requestId = try values.decodeIfPresent(String.self, forKey: .requestId)
        errorCode = try values.decodeIfPresent(String.self, forKey: .errorCode)
            ?? values.decodeIfPresent(String.self, forKey: .code)
        message = try values.decodeIfPresent(String.self, forKey: .message)
            ?? values.decodeIfPresent(String.self, forKey: .errorMessage)
    }
}

struct DantaIntelligencePing: Decodable, Sendable {
    let timestamp: Int64?
}

struct DantaIntelligencePong: Encodable, Sendable {
    let type = "pong"
    let timestamp: Int64
    let version = "1.0"
}

struct DantaIntelligenceSocketRequest<Payload: Encodable & Sendable>: Encodable, Sendable {
    let type: String
    let requestId: String
    let payload: Payload
}

struct DantaIntelligenceSocketResponse<Payload: Decodable & Sendable>: Decodable, Sendable {
    let type: String
    let requestId: String
    let payload: Payload
}

struct DantaIntelligenceEmptyPayload: Encodable, Sendable { }

struct DantaIntelligenceChatSendPayload: Encodable, Sendable {
    let channelId: Int
    let sessionId = ""
    let content: String
    let messageId: String

    private enum CodingKeys: String, CodingKey {
        case channelId, sessionId, content, messageId, media
    }

    func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(channelId, forKey: .channelId)
        try values.encode(sessionId, forKey: .sessionId)
        try values.encode(content, forKey: .content)
        try values.encode(messageId, forKey: .messageId)
        try values.encodeNil(forKey: .media)
    }
}

struct DantaIntelligenceChatAcceptedPayload: Decodable, Sendable {
    let taskId: String
    let channelId: Int
}

public struct DantaIntelligenceRemoteError: Error, LocalizedError, Sendable {
    public let code: String?
    public let message: String
    let statusCode: Int?

    public init(code: String?, message: String, statusCode: Int? = nil) {
        self.code = code
        self.message = message
        self.statusCode = statusCode
    }

    public var errorDescription: String? {
        message.isEmpty ? code : message
    }
}

public enum DantaIntelligenceConnectionState: Sendable {
    case idle
    case connecting
    case recovering
    case ready
    case failed(DantaIntelligenceError)
}

public enum DantaIntelligenceChatTransportEvent: Sendable {
    case connectionState(DantaIntelligenceConnectionState)
    case accepted(runId: String, channelId: Int)
    case message(runId: String, message: DantaIntelligenceMessage)
    case failure(runId: String, error: DantaIntelligenceError)
}
