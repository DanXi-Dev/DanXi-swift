import Foundation

@available(iOS 18.0, *)
public final class DantaIntelligenceChatTransport: OpenClawChatTransport, @unchecked Sendable {
    private let socket: DantaIntelligenceWebSocketClient
    
    public init(
        webSocketURL: URL = dantaIntelligenceWebSocketURL,
        version: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    ) {
        self.socket = DantaIntelligenceWebSocketClient(url: webSocketURL, version: version)
    }
    
    public func requestHistory(sessionKey: String) async throws -> OpenClawChatHistoryPayload {
        guard let channelId = Int(sessionKey) else {
            return OpenClawChatHistoryPayload(
                sessionKey: sessionKey,
                sessionId: sessionKey,
                messages: [],
                thinkingLevel: "off")
        }
        
        let messages = try await DantaIntelligenceAPI.listMessages(
            channelId: channelId,
            sort: "asc",
            size: 100)
        return OpenClawChatHistoryPayload(
            sessionKey: sessionKey,
            sessionId: sessionKey,
            messages: messages.map { AnyCodable.encodable($0.openClawMessage) },
            thinkingLevel: "off")
    }
    
    public func sendMessage(
        sessionKey: String,
        message: String,
        thinking _: String,
        idempotencyKey: String,
        attachments _: [OpenClawChatAttachmentPayload]
    ) async throws -> OpenClawChatSendResponse {
        let isNewChat = DantaIntelligenceSession.isNew(sessionKey)
        let channelId = isNewChat ? 0 : (Int(sessionKey) ?? socket.nextChannelId())
        let messageId = idempotencyKey.isEmpty ? Self.makeMessageId() : idempotencyKey
        try await socket.connectIfNeeded()
        try await socket.sendMessage(
            content: message,
            messageId: messageId,
            channelId: channelId,
            createsNewChat: isNewChat)
        return OpenClawChatSendResponse(
            runId: messageId,
            status: "sent")
    }
    
    public func listSessions(limit: Int?) async throws -> OpenClawChatSessionsListResponse {
        let channels = try await DantaIntelligenceAPI.listChannels()
        let sorted = channels.sorted { $0.updatedAt > $1.updatedAt }
        let limited = limit.map { Array(sorted.prefix($0)) } ?? sorted
        let sessions = limited.map { channel in
            OpenClawChatSessionEntry(
                key: String(channel.userSessionId),
                kind: "danta",
                displayName: String(localized: "Danta Intelligence Session \(channel.userSessionId)", bundle: .module),
                surface: nil,
                subject: nil,
                room: nil,
                space: nil,
                updatedAt: channel.updatedAt.timeIntervalSince1970 * 1000,
                sessionId: String(channel.userSessionId),
                systemSent: nil,
                abortedLastRun: nil,
                thinkingLevel: nil,
                verboseLevel: nil,
                inputTokens: nil,
                outputTokens: nil,
                totalTokens: nil,
                modelProvider: nil,
                model: nil,
                contextTokens: nil)
        }
        let mainKey = sessions.first?.key ?? DantaIntelligenceSession.newSessionKey
        return OpenClawChatSessionsListResponse(
            ts: Date().timeIntervalSince1970 * 1000,
            path: nil,
            count: sessions.count,
            defaults: OpenClawChatSessionsDefaults(
                model: nil,
                contextTokens: nil,
                mainSessionKey: mainKey),
            sessions: sessions)
    }
    
    public func requestHealth(timeoutMs _: Int) async throws -> Bool {
        socket.isConnected
    }
    
    public func listModels() async throws -> [OpenClawChatModelChoice] {
        []
    }
    
    public func events() -> AsyncStream<OpenClawChatTransportEvent> {
        socket.events()
    }
    
    public func setActiveSessionKey(_: String) async throws {
        socket.connectInBackground()
    }
    
    private static func makeMessageId() -> String {
        "msg_\(Int64.dantaNowMilliseconds)_\(UUID().uuidString.prefix(8))"
    }
}

@available(iOS 18.0, *)
private final class DantaIntelligenceWebSocketClient: @unchecked Sendable {
    private let url: URL
    private let version: String
    private let hub = DantaIntelligenceEventHub()
    private let lock = NSLock()
    
    private var task: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var connected = false
    private var authenticated = false
    private var channelCount = 0
    private var pendingNewRunId: String?
    private var pendingRunIdsByChannel: [Int: String] = [:]
    
    var isConnected: Bool {
        lock.lock()
        defer { lock.unlock() }
        return connected
    }
    
    init(url: URL, version: String) {
        self.url = url
        self.version = version
    }
    
    func events() -> AsyncStream<OpenClawChatTransportEvent> {
        hub.stream()
    }

    func connectInBackground() {
        Task { [weak self] in
            try? await self?.connectIfNeeded()
        }
    }
    
    func nextChannelId() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return channelCount
    }
    
    func connectIfNeeded() async throws {
        let connection = {
            lock.lock()
            defer { lock.unlock() }
            if connected, let task {
                return (task, false, !authenticated)
            }
            let task = URLSession.shared.webSocketTask(with: url)
            task.maximumMessageSize = 16 * 1024 * 1024
            self.task = task
            connected = true
            authenticated = false
            return (task, true, true)
        }()
        
        if connection.1 {
            connection.0.resume()
            startReceiveLoop(for: connection.0)
        }
        
        if connection.2 {
            try await sendAuth()
        }
    }
    
    func sendMessage(
        content: String,
        messageId: String,
        channelId: Int,
        createsNewChat: Bool
    ) async throws {
        let timestamp = Int64.dantaNowMilliseconds
        let payload = DantaIntelligenceSocketMessage(
            type: "message",
            from: .client,
            content: content,
            messageId: messageId,
            channelId: channelId,
            timestamp: timestamp,
            media: AnyCodable([:]),
            version: version)
        lock.lock()
        if createsNewChat {
            pendingNewRunId = messageId
        } else {
            pendingRunIdsByChannel[channelId] = messageId
        }
        lock.unlock()
        do {
            try await send(payload)
        } catch {
            if createsNewChat {
                _ = takePendingNewRunId()
            } else {
                _ = takePendingRunId(channelId: channelId)
            }
            throw error
        }
        scheduleHistoryFallback(
            channelId: createsNewChat ? nil : channelId,
            createsNewChat: createsNewChat,
            sentAt: timestamp)
    }
    
    private func sendAuth() async throws {
        guard let token = CredentialStore.shared.token?.access else {
            throw TokenError.none
        }
        let payload = DantaIntelligenceAuthRequest(
            token: token,
            timestamp: .dantaNowMilliseconds,
            version: version)
        try await send(payload)
    }
    
    private func send<T: Encodable>(_ value: T) async throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(value)
        guard let text = String(data: data, encoding: .utf8) else {
            throw DantaIntelligenceTransportError.invalidPayload
        }
        guard let task = currentTask() else {
            throw DantaIntelligenceTransportError.notConnected
        }
        dantaDebugLogWebSocket(direction: "send", payload: text)
        try await task.send(.string(text))
    }
    
    private func currentTask() -> URLSessionWebSocketTask? {
        lock.lock()
        defer { lock.unlock() }
        return task
    }
    
    private func startReceiveLoop(for task: URLSessionWebSocketTask) {
        lock.lock()
        if receiveTask != nil {
            lock.unlock()
            return
        }
        receiveTask = Task { [weak self, weak task] in
            guard let task else { return }
            await self?.receiveLoop(task: task)
        }
        lock.unlock()
    }
    
    private func receiveLoop(task: URLSessionWebSocketTask) async {
        while !Task.isCancelled {
            do {
                let message = try await task.receive()
                try await handle(message)
            } catch {
                dantaDebugLogWebSocket(direction: "receive_error", payload: error.localizedDescription)
                markDisconnected(error: error)
                return
            }
        }
    }
    
    private func handle(_ message: URLSessionWebSocketTask.Message) async throws {
        let data: Data
        switch message {
        case .data(let incoming):
            data = incoming
            dantaDebugLogWebSocket(direction: "receive", data: incoming)
        case .string(let incoming):
            guard let incomingData = incoming.data(using: .utf8) else { return }
            data = incomingData
            dantaDebugLogWebSocket(direction: "receive", payload: incoming)
        @unknown default:
            return
        }
        
        let envelope = try JSONDecoder.defaultDecoder.decode(DantaIntelligenceSocketEnvelope.self, from: data)
        switch envelope.type {
        case "auth_success":
            let payload = try JSONDecoder.defaultDecoder.decode(DantaIntelligenceAuthSuccess.self, from: data)
            lock.lock()
            authenticated = true
            channelCount = payload.channelCount
            lock.unlock()
            hub.yield(.health(ok: true))
        case "message":
            let payload = try JSONDecoder.defaultDecoder.decode(DantaIntelligenceSocketMessage.self, from: data)
            let isAssistant = payload.from.openClawRole == "assistant"
            let runId = isAssistant
                ? takePendingRunId(channelId: payload.channelId) ?? takePendingNewRunId() ?? payload.messageId
                : payload.messageId
            let openClawMessage = isAssistant ? AnyCodable.encodable(payload.openClawMessage) : nil
            hub.yield(.chat(OpenClawChatEventPayload(
                runId: runId,
                sessionKey: String(payload.channelId),
                state: isAssistant ? "final" : "user_echo",
                message: openClawMessage,
                errorMessage: nil)))
        case "error":
            let payload = try JSONDecoder.defaultDecoder.decode(DantaIntelligenceErrorMessage.self, from: data)
            let runId: String?
            if payload.channelId == 0 {
                runId = takePendingNewRunId() ?? payload.messageId
            } else {
                runId = payload.channelId.flatMap { takePendingRunId(channelId: $0) } ?? payload.messageId
            }
            hub.yield(.chat(OpenClawChatEventPayload(
                runId: runId,
                sessionKey: payload.channelId.map(String.init),
                state: "error",
                message: nil,
                errorMessage: payload.errorMessage ?? payload.code ?? String(localized: "Danta Intelligence Error", bundle: .module))))
        case "ping":
            _ = try? JSONDecoder.defaultDecoder.decode(DantaIntelligencePing.self, from: data)
            try await send(DantaIntelligencePong(
                timestamp: .dantaNowMilliseconds,
                version: version))
            hub.yield(.tick)
        default:
            break
        }
    }
    
    private func markDisconnected(error: Error) {
        lock.lock()
        let pendingRuns = pendingRunIdsByChannel.map { (channelId: $0.key, runId: $0.value) }
        let pendingNewRunId = pendingNewRunId
        connected = false
        authenticated = false
        task = nil
        receiveTask = nil
        pendingRunIdsByChannel = [:]
        self.pendingNewRunId = nil
        lock.unlock()
        hub.yield(.health(ok: false))
        
        if let pendingNewRunId {
            hub.yield(.chat(OpenClawChatEventPayload(
                runId: pendingNewRunId,
                sessionKey: nil,
                state: "error",
                message: nil,
                errorMessage: error.localizedDescription)))
        }
        for pendingRun in pendingRuns {
            hub.yield(.chat(OpenClawChatEventPayload(
                runId: pendingRun.runId,
                sessionKey: String(pendingRun.channelId),
                state: "error",
                message: nil,
                errorMessage: error.localizedDescription)))
        }
        if pendingNewRunId == nil, pendingRuns.isEmpty {
            hub.yield(.chat(OpenClawChatEventPayload(
                runId: nil,
                sessionKey: nil,
                state: "error",
                message: nil,
                errorMessage: error.localizedDescription)))
        }
    }

    private func takePendingRunId(channelId: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return pendingRunIdsByChannel.removeValue(forKey: channelId)
    }
    
    private func takePendingNewRunId() -> String? {
        lock.lock()
        defer { lock.unlock() }
        defer { pendingNewRunId = nil }
        return pendingNewRunId
    }
    
    private func pendingRunId(channelId: Int) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return pendingRunIdsByChannel[channelId]
    }
    
    private func currentPendingNewRunId() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return pendingNewRunId
    }
    
    private func scheduleHistoryFallback(channelId: Int?, createsNewChat: Bool, sentAt: Int64) {
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            let deadline = Date().addingTimeInterval(110)
            
            while Date() < deadline {
                guard let self else { return }
                let pendingRunId: String?
                let resolvedChannelId: Int?
                if createsNewChat {
                    pendingRunId = self.currentPendingNewRunId()
                    resolvedChannelId = try? await self.resolveNewChannelId(sentAt: sentAt)
                } else {
                    guard let channelId else { return }
                    pendingRunId = self.pendingRunId(channelId: channelId)
                    resolvedChannelId = channelId
                }
                guard let pendingRunId else { return }
                
                if let resolvedChannelId,
                   let reply = try? await DantaIntelligenceAPI.listMessages(
                    channelId: resolvedChannelId,
                    sort: "desc",
                    size: 8).first(where: {
                        $0.timestamp >= sentAt && $0.from.openClawRole == "assistant"
                    })
                {
                    let runId = createsNewChat
                        ? (self.takePendingNewRunId() ?? pendingRunId)
                        : (self.takePendingRunId(channelId: resolvedChannelId) ?? pendingRunId)
                    self.hub.yield(.chat(OpenClawChatEventPayload(
                        runId: runId,
                        sessionKey: String(resolvedChannelId),
                        state: "final",
                        message: AnyCodable.encodable(reply.openClawMessage),
                        errorMessage: nil)))
                    return
                }
                
                try? await Task.sleep(for: .seconds(2))
            }
            
            guard let self else { return }
            let runId: String?
            let sessionKey: String?
            if createsNewChat {
                runId = self.takePendingNewRunId()
                sessionKey = nil
            } else if let channelId {
                runId = self.takePendingRunId(channelId: channelId)
                sessionKey = String(channelId)
            } else {
                runId = nil
                sessionKey = nil
            }
            guard let runId else { return }
            self.hub.yield(.chat(OpenClawChatEventPayload(
                runId: runId,
                sessionKey: sessionKey,
                state: "error",
                message: nil,
                errorMessage: "No reply was received from Danta Intelligence. Please try again or refresh.")))
        }
    }
    
    private func resolveNewChannelId(sentAt: Int64) async throws -> Int? {
        try await DantaIntelligenceAPI.listChannels()
            .filter { Int64($0.updatedAt.timeIntervalSince1970 * 1000) >= sentAt - 5_000 }
            .max { $0.updatedAt < $1.updatedAt }?
            .userSessionId
    }
}

@available(iOS 18.0, *)
private final class DantaIntelligenceEventHub: @unchecked Sendable {
    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<OpenClawChatTransportEvent>.Continuation] = [:]
    
    func stream() -> AsyncStream<OpenClawChatTransportEvent> {
        let id = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(200)) { continuation in
            self.lock.lock()
            self.continuations[id] = continuation
            self.lock.unlock()
            continuation.onTermination = { [weak self] _ in
                self?.lock.lock()
                self?.continuations.removeValue(forKey: id)
                self?.lock.unlock()
            }
        }
    }
    
    func yield(_ event: OpenClawChatTransportEvent) {
        lock.lock()
        let continuations = Array(continuations.values)
        lock.unlock()
        for continuation in continuations {
            continuation.yield(event)
        }
    }
}

private enum DantaIntelligenceTransportError: Error {
    case invalidPayload
    case notConnected
}

private func dantaDebugLogWebSocket(direction: String, payload: String) {
#if DEBUG
    let redacted = payload.replacingOccurrences(
        of: #""token"\s*:\s*"[^"]*""#,
        with: #""token":"<redacted>""#,
        options: .regularExpression)
    print("[DantaIntelligence][WebSocket][\(direction)] \(redacted)")
#endif
}

private func dantaDebugLogWebSocket(direction: String, data: Data) {
#if DEBUG
    if let text = String(data: data, encoding: .utf8) {
        dantaDebugLogWebSocket(direction: direction, payload: text)
    } else {
        print("[DantaIntelligence][WebSocket][\(direction)] <\(data.count) bytes>")
    }
#endif
}

private extension AnyCodable {
    static func encodable<T: Encodable>(_ value: T) -> AnyCodable {
        guard let data = try? JSONEncoder().encode(value),
              let object = try? JSONSerialization.jsonObject(with: data)
        else {
            return AnyCodable(NSNull())
        }
        return AnyCodable(object)
    }
}
