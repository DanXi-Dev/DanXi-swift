import Foundation

@available(iOS 18.0, *)
public actor DantaIntelligenceChatTransport {
    nonisolated private let eventStream = AsyncStream<DantaIntelligenceChatTransportEvent>.makeStream(
        bufferingPolicy: .bufferingNewest(200))

    private var webSocketTask: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var authenticationTask: Task<Void, Error>?
    private var authenticationGeneration: UUID?
    private var authenticationContinuation: CheckedContinuation<Void, Error>?
    private var recoveryTask: Task<Void, Error>?
    private var recoveryGeneration = UUID()
    private var recoveryDeadline = ContinuousClock.now
    private var connectionGeneration = UUID()
    private var healthTask: Task<Void, Never>?
    private var authenticationToken: String?
    private var rejectedToken: String?
    private var refreshedRejectedToken = false
    public private(set) var connectionState: DantaIntelligenceConnectionState = .idle
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
        recoveryTask?.cancel()
        healthTask?.cancel()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        eventStream.continuation.finish()
    }

    public nonisolated func events() -> AsyncStream<DantaIntelligenceChatTransportEvent> {
        eventStream.stream
    }

    /// Concurrent callers share one recovery. A user retry replaces every old connection task.
    public func ensureReady(forceReconnect: Bool = false) async throws {
        try Task.checkCancellation()
        if forceReconnect {
            cancelRecovery()
            teardownConnection(error: DantaIntelligenceTransportError.notConnected)
        } else if isReady, recoveryTask == nil {
            publish(.ready)
            return
        }
        let task = recoveryTask ?? startRecovery(recovering: forceReconnect)
        try await DantaIntelligenceTaskWaiter<Void>.value(
            of: task, deadline: recoveryDeadline,
            timeoutError: DantaIntelligenceTransportError.requestTimedOut("connection"))
    }

    /// Authentication is also used before an instance exists (onboarding).
    private func ensureAuthenticated(deadline: ContinuousClock.Instant, requestId: String) async throws {
        try Task.checkCancellation()
        if authenticated, webSocketTask != nil { return }
        let task: Task<Void, Error>
        if let authenticationTask {
            task = authenticationTask
        } else {
            let generation = UUID()
            authenticationGeneration = generation
            let newTask = Task { [weak self] in
                guard let self else { throw CancellationError() }
                do {
                    try await DantaIntelligenceRetry.withDeadline(
                        deadline: deadline,
                        timeout: DantaIntelligenceError(
                            DantaIntelligenceTransportError.requestTimedOut("auth"), operation: .connect)
                    ) {
                        try await self.establishAndAuthenticate(generation: generation, deadline: deadline)
                    }
                    await self.authenticationTaskCompleted(generation: generation)
                } catch {
                    await self.failAuthentication(error, generation: generation)
                    throw error
                }
            }
            authenticationTask = newTask
            task = newTask
        }
        try await DantaIntelligenceTaskWaiter<Void>.value(
            of: task, deadline: deadline,
            timeoutError: DantaIntelligenceTransportError.requestTimedOut(requestId))
    }

    public func disconnect() {
        cancelRecovery()
        rejectedToken = nil
        teardownConnection(error: CancellationError())
        publish(.idle)
    }

    private func cancelRecovery() {
        recoveryGeneration = UUID()
        recoveryTask?.cancel()
        recoveryTask = nil
        authenticationTask?.cancel()
    }

    /// No events about connection state are emitted here: the caller owns the transition.
    private func teardownConnection(error: any Error) {
        connectionGeneration = UUID()
        instanceStateGeneration = UUID()
        healthTask?.cancel()
        healthTask = nil
        receiveTask?.cancel()
        receiveTask = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        authenticated = false
        instanceState = nil
        authenticationToken = nil
        finishAuthentication(error: error)
        for requestId in Array(pendingResponses.keys) {
            failPendingResponse(requestId: requestId, error: error)
        }
        let interrupted = Set(chatRuns.values.filter { $0.taskId != nil }.map(\.runId))
        for requestId in Array(chatRuns.keys) { cleanupChatRequest(requestId: requestId) }
        for runId in interrupted {
            eventStream.continuation.yield(.failure(runId: runId, error: DantaIntelligenceError(
                DantaIntelligenceTransportError.deliveryUncertain, operation: .send)))
        }
    }

    private func publish(_ state: DantaIntelligenceConnectionState) {
        connectionState = state
        eventStream.continuation.yield(.connectionState(state))
    }

    @discardableResult
    private func startRecovery(recovering: Bool, requiresReady: Bool = true) -> Task<Void, Error> {
        let generation = UUID()
        recoveryGeneration = generation
        let deadline = ContinuousClock.now.advanced(by: .seconds(30))
        recoveryDeadline = deadline
        refreshedRejectedToken = false
        healthTask?.cancel()
        healthTask = nil
        publish(recovering ? .recovering : .connecting)
        let task = Task { [weak self] in
            guard let self else { throw CancellationError() }
            do {
                try await DantaIntelligenceRetry.perform(
                    operation: .connect, deadline: deadline,
                    shouldRetry: { [weak self] failure in
                        await self?.shouldRetryRecovery(failure, generation: generation) ?? false
                    }
                ) { [weak self] in
                    guard let self else { throw CancellationError() }
                    try await self.attemptConnection(generation: generation, deadline: deadline, requiresReady: requiresReady)
                }
                try await self.finishRecoverySuccessfully(generation: generation, requiresReady: requiresReady)
            } catch {
                await self.finishRecovery(generation: generation, failure: error)
                throw error
            }
        }
        recoveryTask = task
        return task
    }

    private func checkRecovery(_ generation: UUID) throws {
        try Task.checkCancellation()
        guard recoveryGeneration == generation else { throw CancellationError() }
    }

    private func attemptConnection(generation: UUID, deadline: ContinuousClock.Instant, requiresReady: Bool) async throws {
        try checkRecovery(generation)
        teardownConnection(error: DantaIntelligenceTransportError.notConnected)
        if let token = rejectedToken {
            try await Authenticator.shared.refreshDantaToken(ifRejected: token)
            try checkRecovery(generation)
            refreshedRejectedToken = true
            rejectedToken = nil
        }
        try await ensureAuthenticated(deadline: deadline, requestId: "auth")
        try checkRecovery(generation)
        guard requiresReady else { return }
        let status = try await instanceStatus(
            requestId: "status-\(UUID().uuidString)",
            timeout: min(.seconds(5), ContinuousClock.now.duration(to: deadline)))
        try checkRecovery(generation)
        guard status.state.isReady else {
            throw DantaIntelligenceTransportError.instanceNotReady(status.state.rawValue)
        }
    }

    private func shouldRetryRecovery(_ failure: DantaIntelligenceError, generation: UUID) -> Bool {
        guard recoveryGeneration == generation, failure.isAutoRetryable else { return false }
        guard !failure.isInstanceNotReady else { return false }
        if let remote = failure.underlying as? DantaIntelligenceRemoteError,
           remote.code == "AUTH_001", refreshedRejectedToken { return false }
        publish(.recovering)
        return true
    }

    private func finishRecoverySuccessfully(generation: UUID, requiresReady: Bool) throws {
        try checkRecovery(generation)
        guard authenticated, !requiresReady || isReady else {
            throw DantaIntelligenceTransportError.notConnected
        }
        recoveryTask = nil
        if requiresReady {
            publish(.ready)
            startHealthChecks()
        } else {
            publish(.idle)
        }
    }

    private func finishRecovery(generation: UUID, failure: any Error) {
        guard recoveryGeneration == generation else { return }
        recoveryTask = nil
        authenticationTask?.cancel()
        teardownConnection(error: failure)
        if DantaIntelligenceError.isCancellation(failure) { publish(.idle) }
        else {
            let issue = DantaIntelligenceError(failure, operation: .connect)
            log(issue)
            publish(.failed(issue))
        }
    }

    private func startHealthChecks() {
        healthTask?.cancel()
        let generation = connectionGeneration
        let interval: Duration = .seconds(10)
        healthTask = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: interval) } catch { return }
                guard let self, await self.checkHealth(generation: generation) else { return }
            }
        }
    }

    private func checkHealth(generation: UUID) async -> Bool {
        guard connectionGeneration == generation, recoveryTask == nil, isReady else { return false }
        do {
            let status = try await instanceStatus(requestId: "status-\(UUID().uuidString)",
                                                  timeout: .seconds(5))
            guard connectionGeneration == generation, !Task.isCancelled else { return false }
            guard status.state.isReady else {
                let error = DantaIntelligenceTransportError.instanceNotReady(status.state.rawValue)
                teardownConnection(error: error)
                publish(.failed(DantaIntelligenceError(error, operation: .connect)))
                return false
            }
            return true
        } catch {
            guard connectionGeneration == generation, !Task.isCancelled else { return false }
            connectionFailed(error)
            return false
        }
    }

    private func connectionFailed(_ error: any Error) {
        let failure = DantaIntelligenceError(error, operation: .connect)
        log(failure)
        teardownConnection(error: error)
        // An in-flight owner observes the same error through its continuation.
        guard recoveryTask == nil else { return }
        if failure.isAutoRetryable, !failure.isInstanceNotReady {
            startRecovery(recovering: true)
        } else {
            publish(.failed(failure))
        }
    }

    private func log(_ failure: DantaIntelligenceError) {
#if DEBUG
        print("[DantaIntelligence][Connection \(connectionGeneration)] \(failure.diagnosticDescription)")
#endif
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
            }
            return response.payload
        } catch {
            if instanceStateGeneration == generation, !DantaIntelligenceError.isCancellation(error) {
                instanceState = nil
            }
            throw error
        }
    }

    public func onboard(requestId: String) async throws -> DantaIntelligenceInstanceStatus {
        try Task.checkCancellation()
        cancelRecovery()
        teardownConnection(error: CancellationError())
        // First setup needs valid credentials, but cannot require an existing ready instance.
        let connection = startRecovery(recovering: false, requiresReady: false)
        try await DantaIntelligenceTaskWaiter<Void>.value(
            of: connection, deadline: recoveryDeadline,
            timeoutError: DantaIntelligenceTransportError.requestTimedOut("connection"))
        instanceState = .provisioning
        let response: DantaIntelligenceSocketResponse<DantaIntelligenceInstanceStatus> = try await request(
            type: "openclaw.onboard",
            responseType: "openclaw.onboard.status",
            requestId: requestId,
            payload: DantaIntelligenceOnboardPayload(),
            timeout: .seconds(900))
        instanceState = response.payload.state
        if isReady, recoveryTask == nil {
            publish(.ready)
            startHealthChecks()
        }
        return response.payload
    }

    public func sendMessage(channelId: Int?, message: String, idempotencyKey: String) async throws {
        if let channelId, channelId <= 0 { throw DantaIntelligenceTransportError.invalidSession }
        let runId = idempotencyKey.isEmpty ? UUID().uuidString : idempotencyKey
        let requestId = "chat-\(runId)"
        if !isReady { try await ensureReady() }

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

    private func establishAndAuthenticate(generation: UUID, deadline: ContinuousClock.Instant) async throws {
        _ = try await DantaIntelligenceAPI.instanceStatus()
        guard let token = CredentialStore.shared.token?.access else { throw TokenError.none }
        try Task.checkCancellation()
        guard authenticationGeneration == generation else {
            throw CancellationError()
        }
        guard ContinuousClock.now < deadline else {
            throw DantaIntelligenceTransportError.requestTimedOut("auth")
        }
        if webSocketTask == nil {
            let task = URLSession.shared.webSocketTask(with: dantaIntelligenceWebSocketURL)
            task.maximumMessageSize = 16 * 1024 * 1024
            webSocketTask = task
            authenticated = false
            task.resume()
            startReceiveLoop(for: task)
        }
        authenticationToken = token
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
        try await ensureAuthenticated(deadline: min(deadline, ContinuousClock.now.advanced(by: .seconds(20))),
                                      requestId: requestId)
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

    private func sendAndWait<Request: Encodable & Sendable>(
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
                    await self?.sendPending(request, requestId: requestId, generation: generation)
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

    private func sendPending<Request: Encodable & Sendable>(
        _ request: Request, requestId: String, generation: UUID
    ) async {
        guard pendingResponses[requestId]?.generation == generation, let socket = webSocketTask else { return }
        do {
            try await send(request, on: socket)
        } catch {
            failPendingResponse(requestId: requestId, error: error, generation: generation)
            if webSocketTask === socket { connectionFailed(error) }
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
        case .string(let incoming):
            data = Data(incoming.utf8)
        @unknown default:
            return
        }

        let envelope = try JSONDecoder.defaultDecoder.decode(
            DantaIntelligenceSocketEnvelope.self,
            from: data)
        switch envelope.type {
        case "auth_success":
            authenticated = true
            let continuation = authenticationContinuation
            authenticationContinuation = nil
            continuation?.resume()
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
            if payload.errorCode == "AUTH_001" {
                rejectedToken = authenticationToken
                throw error
            }
            if !authenticated { throw error }
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
            }
            if payload.errorCode == "CLAW_001" || (!resolvedPending && payload.requestId == nil) {
                connectionFailed(error)
            }
        case "ping":
            guard authenticated else { return }
            let ping = try JSONDecoder.defaultDecoder.decode(
                DantaIntelligencePing.self,
                from: data)
            try await send(DantaIntelligencePong(
                timestamp: ping.timestamp ?? Int64(Date().timeIntervalSince1970 * 1000)))
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

    private func failAuthentication(_ error: any Error, generation: UUID? = nil) {
        if let generation {
            guard authenticationGeneration == generation, !authenticated else { return }
        }
        connectionFailed(error)
    }

    private func finishAuthentication(error: any Error) {
        let continuation = authenticationContinuation
        authenticationContinuation = nil
        authenticationTask = nil
        authenticationGeneration = nil
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

    private func markDisconnected(task: URLSessionWebSocketTask, error: any Error) {
        guard webSocketTask === task else { return }
        connectionFailed(error)
    }

    private func scheduleHistoryFallback(taskId: String, channelId: Int) {
        guard let requestId = requestIdsByTaskId[taskId] else { return }
        chatRuns[requestId]?.fallback = Task { [weak self] in
            for _ in 0..<55 {
                do {
                    try await Task.sleep(for: .seconds(2))
                    guard let self, await self.requestIdsByTaskId[taskId] == requestId else { return }
                    if let reply = try await DantaIntelligenceAPI.listMessages(channelId: channelId, sort: "desc", size: 8)
                        .first(where: { $0.taskId == taskId && !$0.from.isUser }) {
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
