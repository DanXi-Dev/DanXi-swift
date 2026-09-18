import Foundation

@available(iOS 18.0, *)
public actor DantaIntelligenceChatTransport {
    nonisolated private let eventStream = AsyncStream<DantaIntelligenceChatTransportEvent>.makeStream(
        bufferingPolicy: .bufferingNewest(200))

    private let url = dantaIntelligenceWebSocketURL
    private var webSocketTask: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var authenticationTask: Task<Void, Error>?
    private var authenticationGeneration: UUID?
    private var authenticationContinuation: CheckedContinuation<Void, Error>?
    private var authenticationTimeoutTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var authenticated = false
    private var instanceState: DantaIntelligenceInstanceState?
    private var instanceStateGeneration = UUID()

    private struct PendingResponse {
        let generation: UUID
        let continuation: CheckedContinuation<Data, Error>
        let timeout: Task<Void, Never>
    }

    private struct ChatRun {
        let runId: String
        var taskId: String?
        var fallback: Task<Void, Never>?
    }

    private var pendingResponses: [String: PendingResponse] = [:]
    private var chatRuns: [String: ChatRun] = [:]
    private var requestIdsByTaskId: [String: String] = [:]
    private var completedTaskIds: [String] = []

    private var isReady: Bool {
        authenticated && instanceState?.isReady == true
    }

    public init() { }

    deinit {
        receiveTask?.cancel()
        reconnectTask?.cancel()
        authenticationTimeoutTask?.cancel()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        eventStream.continuation.finish()
    }

    public nonisolated func events() -> AsyncStream<DantaIntelligenceChatTransportEvent> {
        eventStream.stream
    }

    public func connectIfNeeded(
        waitTimeout: Duration? = nil,
        timeoutRequestId: String = "auth"
    ) async throws {
        if authenticated, webSocketTask != nil {
            return
        }

        let task: Task<Void, Error>
        if let authenticationTask {
            task = authenticationTask
        } else {
            let generation = UUID()
            authenticationGeneration = generation
            let newTask = Task { [weak self] in
                guard let self else { throw CancellationError() }
                try await self.establishAndAuthenticate(generation: generation)
            }
            authenticationTask = newTask
            task = newTask
            Task.detached { [weak self] in
                _ = await newTask.result
                await self?.authenticationTaskCompleted(generation: generation)
            }
        }

        if let waitTimeout {
            try await Self.waitForAuthentication(
                task,
                timeout: waitTimeout,
                timeoutRequestId: timeoutRequestId)
        } else {
            try await task.value
        }
    }

    public func disconnect() {
        instanceStateGeneration = UUID()
        reconnectTask?.cancel()
        reconnectTask = nil
        authenticationTimeoutTask?.cancel()
        authenticationTimeoutTask = nil
        receiveTask?.cancel()
        receiveTask = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        authenticated = false
        instanceState = nil
        authenticationTask?.cancel()
        failAuthentication(CancellationError())
        for requestId in Array(pendingResponses.keys) {
            failPendingResponse(requestId: requestId, error: CancellationError())
        }
        for requestId in Array(chatRuns.keys) {
            cleanupChatRequest(requestId: requestId)
        }
        eventStream.continuation.yield(.health(ok: false))
    }

    private func instanceStatus(
        requestId: String,
        timeout: Duration = .seconds(30)
    ) async throws -> DantaIntelligenceInstanceStatus {
        let generation = UUID()
        instanceStateGeneration = generation
        do {
            let response: DantaIntelligenceSocketResponse<DantaIntelligenceInstanceStatus> = try await request(
                type: "openclaw.instance.status",
                responseType: "openclaw.instance.status",
                requestId: requestId,
                payload: DantaIntelligenceEmptyPayload(),
                timeout: timeout)
            if instanceStateGeneration == generation {
                instanceState = response.payload.state
                eventStream.continuation.yield(.health(ok: isReady))
            }
            return response.payload
        } catch {
            if instanceStateGeneration == generation, !DantaIntelligenceError.isCancellation(error) {
                instanceState = nil
                eventStream.continuation.yield(.health(ok: false))
            }
            throw error
        }
    }

    public func requestHealth() async throws -> Bool {
        let status = try await instanceStatus(
            requestId: "status-\(UUID().uuidString)",
            timeout: .seconds(5))
        return authenticated && status.state.isReady
    }

    public func onboard(requestId: String) async throws -> DantaIntelligenceInstanceStatus {
        instanceState = .provisioning
        eventStream.continuation.yield(.health(ok: false))
        let response: DantaIntelligenceSocketResponse<DantaIntelligenceInstanceStatus> = try await request(
            type: "openclaw.onboard",
            responseType: "openclaw.onboard.status",
            requestId: requestId,
            payload: DantaIntelligenceOnboardPayload(),
            timeout: .seconds(900))
        instanceState = response.payload.state
        eventStream.continuation.yield(.health(ok: isReady))
        return response.payload
    }

    public func sendMessage(channelId: Int?, message: String, idempotencyKey: String) async throws {
        if let channelId, channelId <= 0 { throw DantaIntelligenceTransportError.invalidSession }
        let runId = idempotencyKey.isEmpty ? UUID().uuidString : idempotencyKey
        let requestId = "chat-\(runId)"
        if !isReady {
            let status = try await instanceStatus(requestId: "status-\(UUID().uuidString)")
            guard status.state.isReady else {
                throw DantaIntelligenceTransportError.instanceNotReady(status.state.rawValue)
            }
        }

        guard chatRuns[requestId] == nil else {
            throw DantaIntelligenceTransportError.duplicateRequest(requestId)
        }
        chatRuns[requestId] = ChatRun(runId: runId)
        do {
            let response: DantaIntelligenceSocketResponse<DantaIntelligenceChatAcceptedPayload> = try await request(
                type: "openclaw.chat.send",
                responseType: "openclaw.chat.accepted",
                requestId: requestId,
                payload: DantaIntelligenceChatSendPayload(
                    channelId: channelId ?? 0,
                    content: message,
                    messageId: "message-\(runId)"),
                timeout: .seconds(30))
            scheduleHistoryFallback(
                taskId: response.payload.taskId,
                channelId: response.payload.channelId)
        } catch {
            cleanupChatRequest(requestId: requestId)
            throw error
        }
    }

    private func establishAndAuthenticate(generation: UUID) async throws {
        // Refresh the HTTP credential before authenticating the socket.
        _ = try await DantaIntelligenceAPI.instanceStatus()
        guard let token = CredentialStore.shared.token?.access else { throw TokenError.none }
        try Task.checkCancellation()
        guard authenticationGeneration == generation else {
            throw CancellationError()
        }
        if webSocketTask == nil {
            let task = URLSession.shared.webSocketTask(with: url)
            task.maximumMessageSize = 16 * 1024 * 1024
            webSocketTask = task
            authenticated = false
            task.resume()
            startReceiveLoop(for: task)
        }
        try await authenticate(token: token, generation: generation)
    }

    private func authenticate(token: String, generation: UUID) async throws {
        let payload = DantaIntelligenceAuthRequest(token: token)

        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            guard authenticationGeneration == generation else {
                continuation.resume(throwing: CancellationError())
                return
            }
            authenticationContinuation = continuation
            authenticationTimeoutTask?.cancel()
            authenticationTimeoutTask = Task.detached { [weak self] in
                try? await Task.sleep(for: .seconds(20))
                guard !Task.isCancelled else { return }
                await self?.failAuthentication(
                    DantaIntelligenceTransportError.requestTimedOut("auth"),
                    generation: generation)
            }
            Task { [weak self] in
                await self?.sendAuthentication(
                    payload,
                    generation: generation)
            }
        }
    }

    private func request<RequestPayload, ResponsePayload>(
        type: String,
        responseType: String,
        requestId: String,
        payload: RequestPayload,
        timeout: Duration
    ) async throws -> DantaIntelligenceSocketResponse<ResponsePayload>
    where RequestPayload: Encodable & Sendable, ResponsePayload: Decodable & Sendable {
        let deadline = ContinuousClock.now.advanced(by: timeout)
        let authenticationBudget = ContinuousClock.now.duration(to: deadline)
        guard authenticationBudget > .zero else {
            throw DantaIntelligenceTransportError.requestTimedOut(requestId)
        }
        try await connectIfNeeded(
            waitTimeout: min(authenticationBudget, .seconds(20)),
            timeoutRequestId: requestId)
        let responseBudget = ContinuousClock.now.duration(to: deadline)
        guard responseBudget > .zero else {
            throw DantaIntelligenceTransportError.requestTimedOut(requestId)
        }
        let request = DantaIntelligenceSocketRequest(
            type: type,
            requestId: requestId,
            payload: payload)
        let connection = webSocketTask
        let data = try await sendAndWait(
            request,
            requestId: requestId,
            timeout: responseBudget)
        guard webSocketTask === connection else { throw CancellationError() }
        let response = try JSONDecoder.defaultDecoder.decode(
            DantaIntelligenceSocketResponse<ResponsePayload>.self,
            from: data)
        guard response.type == responseType else {
            throw DantaIntelligenceTransportError.unexpectedResponse(
                expected: responseType,
                received: response.type)
        }
        return response
    }

    private func sendAndWait<Request: Encodable>(
        _ request: Request,
        requestId: String,
        timeout: Duration
    ) async throws -> Data {
        guard pendingResponses[requestId] == nil else {
            throw DantaIntelligenceTransportError.duplicateRequest(requestId)
        }

        let generation = UUID()
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<Data, Error>) in
                let timeoutTask = Task.detached { [weak self] in
                    try? await Task.sleep(for: timeout)
                    guard !Task.isCancelled else { return }
                    await self?.failPendingResponse(
                        requestId: requestId,
                        error: DantaIntelligenceTransportError.requestTimedOut(requestId),
                        generation: generation)
                }
                pendingResponses[requestId] = PendingResponse(
                    generation: generation, continuation: continuation, timeout: timeoutTask)
                Task { [weak self] in
                    guard let self, await self.pendingResponses[requestId]?.generation == generation else { return }
                    do {
                        try await self.send(request)
                    } catch {
                        await self.failPendingResponse(requestId: requestId, error: error, generation: generation)
                    }
                }
            }
        } onCancel: {
            Task { [weak self] in
                await self?.failPendingResponse(
                    requestId: requestId,
                    error: CancellationError(),
                    generation: generation)
            }
        }
    }

    private func send<Value: Encodable>(_ value: Value) async throws {
        guard let webSocketTask else {
            throw DantaIntelligenceTransportError.notConnected
        }
        try await send(value, on: webSocketTask)
    }

    private func send<Value: Encodable>(
        _ value: Value,
        on task: URLSessionWebSocketTask
    ) async throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let text = String(decoding: try encoder.encode(value), as: UTF8.self)
        dantaDebugLogWebSocket(direction: "send", payload: text)
        try await task.send(.string(text))
    }

    private func startReceiveLoop(for task: URLSessionWebSocketTask) {
        receiveTask?.cancel()
        receiveTask = Task { [weak self, weak task] in
            guard let task else { return }
            while !Task.isCancelled {
                do {
                    let message = try await task.receive()
                    try await self?.handle(message, from: task)
                } catch {
                    await self?.markDisconnected(task: task, error: error)
                    return
                }
            }
        }
    }

    private func handle(
        _ message: URLSessionWebSocketTask.Message,
        from task: URLSessionWebSocketTask
    ) async throws {
        guard webSocketTask === task else { return }
        let data: Data
        switch message {
        case .data(let incoming):
            data = incoming
            dantaDebugLogWebSocket(direction: "receive", data: incoming)
        case .string(let incoming):
            data = Data(incoming.utf8)
            dantaDebugLogWebSocket(direction: "receive", payload: incoming)
        @unknown default:
            return
        }

        let envelope = try JSONDecoder.defaultDecoder.decode(
            DantaIntelligenceSocketEnvelope.self,
            from: data)
        switch envelope.type {
        case "auth_success":
            authenticated = true
            authenticationTimeoutTask?.cancel()
            authenticationTimeoutTask = nil
            let continuation = authenticationContinuation
            authenticationContinuation = nil
            continuation?.resume()
            eventStream.continuation.yield(.tick)
        case "openclaw.instance.status", "openclaw.onboard.status":
            if let requestId = envelope.requestId {
                completePendingResponse(requestId: requestId, data: data)
            }
        case "openclaw.chat.accepted":
            let response = try JSONDecoder.defaultDecoder.decode(
                DantaIntelligenceSocketResponse<DantaIntelligenceChatAcceptedPayload>.self,
                from: data)
            if pendingResponses[response.requestId] != nil,
               let runId = chatRuns[response.requestId]?.runId {
                chatRuns[response.requestId]?.taskId = response.payload.taskId
                requestIdsByTaskId[response.payload.taskId] = response.requestId
                // Register the task-to-run mapping before resuming the send request.
                eventStream.continuation.yield(.accepted(runId: runId, channelId: response.payload.channelId))
            }
            completePendingResponse(requestId: response.requestId, data: data)
        case "message":
            let payload = try JSONDecoder.defaultDecoder.decode(
                DantaIntelligenceMessage.self,
                from: data)
            let isAssistant = !payload.from.isUser
            let runId: String
            if isAssistant, let taskId = payload.taskId {
                guard !completedTaskIds.contains(taskId) else { return }
                runId = takeRunId(taskId: taskId) ?? taskId
                rememberCompleted(taskId)
            } else {
                runId = payload.taskId ?? payload.messageId
            }
            eventStream.continuation.yield(.message(runId: runId, message: payload))
        case "error", "openclaw.error":
            let payload = try JSONDecoder.defaultDecoder.decode(
                DantaIntelligenceErrorMessage.self,
                from: data)
            let error = DantaIntelligenceRemoteError(
                code: payload.errorCode,
                message: payload.message ?? payload.errorCode ?? String(
                    localized: "Danta Intelligence Error",
                    bundle: .module))
            if payload.errorCode == "AUTH_001", authenticated { throw error }
            if payload.errorCode == "CLAW_001" {
                instanceState = nil
                eventStream.continuation.yield(.health(ok: false))
            }
            if !authenticated {
                failAuthentication(
                    error,
                    generation: authenticationGeneration)
            }
            let resolvedPending = payload.requestId.map {
                failPendingResponse(requestId: $0, error: error)
            } ?? false
            if !resolvedPending,
               let requestId = payload.requestId,
               let taskId = chatRuns[requestId]?.taskId,
               let runId = takeRunId(taskId: taskId)
            {
                eventStream.continuation.yield(.failure(runId: runId,
                    error: DantaIntelligenceError(error, operation: .send)))
            } else if !resolvedPending, payload.requestId == nil {
                let issue = DantaIntelligenceError(error, operation: .connect)
                eventStream.continuation.yield(.connectionError(issue))
            }
        case "ping":
            guard authenticated else { return }
            let ping = try JSONDecoder.defaultDecoder.decode(
                DantaIntelligencePing.self,
                from: data)
            try await send(DantaIntelligencePong(
                timestamp: ping.timestamp ?? Int64(Date().timeIntervalSince1970 * 1000)))
            eventStream.continuation.yield(.tick)
        default:
            break
        }
    }

    private func completePendingResponse(requestId: String, data: Data) {
        guard let pending = pendingResponses.removeValue(forKey: requestId) else { return }
        pending.timeout.cancel()
        pending.continuation.resume(returning: data)
    }

    @discardableResult
    private func failPendingResponse(requestId: String, error: Error, generation: UUID? = nil) -> Bool {
        guard let pending = pendingResponses[requestId],
              generation == nil || pending.generation == generation else { return false }
        pendingResponses.removeValue(forKey: requestId)
        pending.timeout.cancel()
        pending.continuation.resume(throwing: error)
        return true
    }

    private func failAuthentication(
        _ error: Error,
        generation: UUID? = nil
    ) {
        if let generation {
            guard authenticationGeneration == generation,
                  authenticationContinuation != nil,
                  !authenticated
            else {
                return
            }
        }
        authenticationTimeoutTask?.cancel()
        authenticationTimeoutTask = nil
        let continuation = authenticationContinuation
        authenticationContinuation = nil
        authenticationTask = nil
        authenticationGeneration = nil
        authenticated = false
        instanceState = nil
        if let task = webSocketTask {
            webSocketTask = nil
            receiveTask?.cancel()
            receiveTask = nil
            task.cancel(with: .goingAway, reason: nil)
            eventStream.continuation.yield(.health(ok: false))
        }
        continuation?.resume(throwing: error)
    }

    private func sendAuthentication(
        _ payload: DantaIntelligenceAuthRequest,
        generation: UUID
    ) async {
        guard authenticationGeneration == generation,
              !authenticated
        else {
            return
        }
        guard let task = webSocketTask else {
            failAuthentication(
                DantaIntelligenceTransportError.notConnected,
                generation: generation)
            return
        }
        do {
            try await send(payload, on: task)
        } catch {
            guard webSocketTask === task else { return }
            failAuthentication(error, generation: generation)
        }
    }

    private func authenticationTaskCompleted(generation: UUID) {
        guard authenticationGeneration == generation else { return }
        authenticationTask = nil
        authenticationGeneration = nil
    }

    nonisolated private static func waitForAuthentication(
        _ task: Task<Void, Error>,
        timeout: Duration,
        timeoutRequestId: String
    ) async throws {
        let waiter = DantaIntelligenceAuthenticationWaiter()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<Void, Error>) in
                guard waiter.install(continuation) else { return }
                waiter.track(Task.detached {
                    do {
                        try await task.value
                        waiter.resolve(.success(()))
                    } catch {
                        waiter.resolve(.failure(error))
                    }
                })
                waiter.track(Task.detached {
                    try? await Task.sleep(for: max(timeout, .milliseconds(1)))
                    guard !Task.isCancelled else { return }
                    waiter.resolve(.failure(
                        DantaIntelligenceTransportError.requestTimedOut(
                            timeoutRequestId)))
                })
            }
        } onCancel: {
            waiter.resolve(.failure(CancellationError()))
        }
    }

    private func markDisconnected(task: URLSessionWebSocketTask, error: Error) {
        guard webSocketTask === task else { return }
        task.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        receiveTask = nil
        authenticated = false
        instanceState = nil
        failAuthentication(error)

        for requestId in Array(pendingResponses.keys) {
            failPendingResponse(requestId: requestId, error: error)
        }
        let interruptedRunIds = Set(chatRuns.values.filter { $0.taskId != nil }.map(\.runId))
        for requestId in Array(chatRuns.keys) {
            cleanupChatRequest(requestId: requestId)
        }
        eventStream.continuation.yield(.health(ok: false))
        for runId in interruptedRunIds {
            eventStream.continuation.yield(.failure(runId: runId,
                error: DantaIntelligenceError(error, operation: .send)))
        }
        let issue = DantaIntelligenceError(error, operation: .connect)
        eventStream.continuation.yield(.connectionError(issue))
        scheduleReconnect()
    }

    private func scheduleReconnect() {
        guard reconnectTask == nil else { return }
        reconnectTask = Task.detached { [weak self] in
            var delay = 1.0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled, let self else { return }
                do {
                    try await self.connectIfNeeded()
                    _ = try await self.instanceStatus(
                        requestId: "status-\(UUID().uuidString)")
                    await self.finishReconnect()
                    return
                } catch {
                    delay = min(delay * 2, 30)
                }
            }
        }
    }

    private func finishReconnect() {
        reconnectTask = nil
    }

    private func scheduleHistoryFallback(taskId: String, channelId: Int) {
        guard let requestId = requestIdsByTaskId[taskId] else { return }
        chatRuns[requestId]?.fallback = Task { [weak self] in
            for _ in 0..<55 {
                do {
                    try await Task.sleep(for: .seconds(2))
                    guard let self, await self.requestIdsByTaskId[taskId] == requestId else { return }
                    if let reply = try await DantaIntelligenceAPI.listMessages(
                        channelId: channelId, sort: "desc", size: 8
                    ).first(where: { $0.taskId == taskId && !$0.from.isUser }) {
                        await self.completeFromHistory(reply, taskId: taskId)
                        return
                    }
                } catch {
                    if Task.isCancelled || DantaIntelligenceError.isCancellation(error) { return }
                    // Push may still complete this run; report a failure only once both paths expire.
                }
            }
            await self?.failChatTask(taskId: taskId)
        }
    }

    private func completeFromHistory(
        _ reply: DantaIntelligenceMessage,
        taskId: String
    ) {
        guard let runId = takeRunId(taskId: taskId) else { return }
        rememberCompleted(taskId)
        eventStream.continuation.yield(.message(runId: runId, message: reply))
    }

    private func failChatTask(taskId: String) {
        guard let runId = takeRunId(taskId: taskId) else { return }
        eventStream.continuation.yield(.failure(runId: runId,
            error: DantaIntelligenceError(DantaIntelligenceTransportError.replyTimedOut, operation: .send)))
    }

    private func takeRunId(taskId: String) -> String? {
        guard let requestId = requestIdsByTaskId[taskId], let run = chatRuns[requestId] else { return nil }
        cleanupChatRequest(requestId: requestId)
        return run.runId
    }

    private func cleanupChatRequest(requestId: String) {
        guard let run = chatRuns.removeValue(forKey: requestId) else { return }
        run.fallback?.cancel()
        if let taskId = run.taskId {
            requestIdsByTaskId.removeValue(forKey: taskId)
        }
    }

    private func rememberCompleted(_ taskId: String) {
        completedTaskIds.append(taskId)
        if completedTaskIds.count > 200 { completedTaskIds.removeFirst() }
    }

}

@available(iOS 18.0, *)
private final class DantaIntelligenceAuthenticationWaiter: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Void, Error>?
    private var resolution: Result<Void, Error>?
    private var isResolved = false
    private var tasks: [Task<Void, Never>] = []

    func track(_ task: Task<Void, Never>) {
        lock.lock()
        let resolved = isResolved
        if !resolved { tasks.append(task) }
        lock.unlock()
        if resolved { task.cancel() }
    }

    @discardableResult
    func install(_ continuation: CheckedContinuation<Void, Error>) -> Bool {
        lock.lock()
        if isResolved {
            let resolution = resolution
            lock.unlock()
            if let resolution {
                continuation.resume(with: resolution)
            }
            return false
        }
        self.continuation = continuation
        lock.unlock()
        return true
    }

    func resolve(_ resolution: Result<Void, Error>) {
        lock.lock()
        guard !isResolved else {
            lock.unlock()
            return
        }
        isResolved = true
        let continuation = continuation
        self.continuation = nil
        self.resolution = resolution
        let tasks = tasks
        self.tasks = []
        lock.unlock()
        tasks.forEach { $0.cancel() }
        continuation?.resume(with: resolution)
    }
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
