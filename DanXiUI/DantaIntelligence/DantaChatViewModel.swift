import DanXiKit
import Foundation
import Observation

@MainActor
@Observable
@available(iOS 18.0, *)
final class DantaChatViewModel {
    private(set) var messages: [DantaIntelligenceMessage] = []
    private(set) var sessions: [DantaIntelligenceChannel] = []
    private(set) var placeholderSessionId: Int?
    private(set) var channelId: Int?
    var input = ""
    private(set) var isLoading = false
    private(set) var isSending = false
    private(set) var isLoadingSessions = false
    private var connectionState: DantaIntelligenceConnectionState = .idle
    private(set) var issue: DantaIntelligenceError?
    private(set) var sessionsIssue: DantaIntelligenceError?
    private var pendingRunId: String?

    @ObservationIgnored private let transport: DantaIntelligenceChatTransport
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private nonisolated(unsafe) var eventTask: Task<Void, Never>?
    @ObservationIgnored private nonisolated(unsafe) var replyTimeoutTask: Task<Void, Never>?
    @ObservationIgnored private nonisolated(unsafe) var historyTask: Task<Void, Never>?
    private var loadGeneration = UUID()
    private var sessionsGeneration = UUID()
    private var isPaused = true
    private var unconfirmedMessageIds = Set<String>()

    init(transport: DantaIntelligenceChatTransport) {
        self.transport = transport
        eventTask = Task { [weak self] in
            for await event in transport.events() {
                guard !Task.isCancelled, let self else { return }
                self.handle(event)
            }
        }
    }

    deinit {
        eventTask?.cancel()
        replyTimeoutTask?.cancel()
        historyTask?.cancel()
        let transport = transport
        Task { await transport.disconnect() }
    }

    var healthOK: Bool {
        if case .ready = connectionState { true } else { false }
    }
    var isCheckingConnection: Bool {
        if case .connecting = connectionState { true } else { false }
    }
    var isRecovering: Bool {
        if case .recovering = connectionState { true } else { false }
    }
    var pendingRunCount: Int { pendingRunId == nil ? 0 : 1 }
    var canSend: Bool {
        healthOK && !isLoading && !isSending && pendingRunId == nil
            && issue?.requiresLogin != true && !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func refresh(reconnect: Bool = false) {
        loadTask?.cancel()
        loadTask = Task { await bootstrap(reconnect: reconnect) }
    }

    func pause() {
        isPaused = true
        loadGeneration = UUID()
        sessionsGeneration = UUID()
        loadTask?.cancel()
        loadTask = nil
        historyTask?.cancel()
        historyTask = nil
        isLoading = false
        isLoadingSessions = false
        connectionState = .idle
        isSending = false
        clearPendingRun()
    }

    func resetForDeletedInstance() {
        pause()
        channelId = nil
        messages = []
        sessions = []
        placeholderSessionId = nil
        unconfirmedMessageIds = []
        input = ""
        issue = nil
        sessionsIssue = nil
    }

    func switchSession(to id: Int?) {
        guard id != channelId else { return }
        loadGeneration = UUID()
        channelId = id
        messages = []
        unconfirmedMessageIds = []
        refresh()
    }

    func loadSessions() async {
        let generation = UUID()
        sessionsGeneration = generation
        isLoadingSessions = true
        defer { if sessionsGeneration == generation { isLoadingSessions = false } }
        do {
            let channels = try await DantaIntelligenceAPI.listChannels()
            guard sessionsGeneration == generation, !Task.isCancelled else { return }
            sessions = Array(channels.sorted { $0.updatedAt > $1.updatedAt }.prefix(50))
            placeholderSessionId = nil
            sessionsIssue = nil
        } catch {
            guard sessionsGeneration == generation, !DantaIntelligenceError.isCancellation(error) else { return }
            sessionsIssue = DantaIntelligenceError(error, operation: .history)
        }
    }

    func send() {
        Task { await performSend() }
    }

    private func bootstrap(reconnect: Bool = false) async {
        guard !Task.isCancelled else { return }
        let generation = UUID()
        loadGeneration = generation
        isPaused = false
        isLoading = true
        isSending = false
        historyTask?.cancel()
        historyTask = nil
        if pendingRunId != nil {
            report(DantaIntelligenceTransportError.deliveryUncertain, operation: .send)
        }
        clearPendingRun()
        if reconnect { connectionState = .recovering }
        defer { if loadGeneration == generation { isLoading = false } }

        // A broken history request must never prevent the retry button from replacing
        // the connection. Each branch records its own result without cancelling the other.
        async let connection: Void = loadConnection(reconnect: reconnect, generation: generation)
        async let history: Void = loadHistory(channelId: channelId, generation: generation)
        _ = await (connection, history)
    }

    private func loadConnection(reconnect: Bool, generation: UUID) async {
        do {
            try await transport.ensureReady(forceReconnect: reconnect)
            guard loadGeneration == generation, !Task.isCancelled else { return }
            Task { [weak self] in await self?.loadSessions() }
        } catch {
            // The transport publishes the current result; an older waiter's error
            // must not overwrite a newer connection event.
        }
    }

    private func loadHistory(channelId: Int?, generation: UUID) async {
        do {
            let incoming = try await retriedHistory(for: channelId)
            guard loadGeneration == generation, !Task.isCancelled else { return }
            mergeHistory(incoming)
            clearIssue(for: .history)
        } catch {
            guard loadGeneration == generation, !Task.isCancelled else { return }
            report(error, operation: .history)
        }
    }

    private func performSend() async {
        guard canSend else { return }
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let generation = loadGeneration
        let channelId = channelId
        let runId = UUID().uuidString
        isSending = true
        pendingRunId = runId
        replyTimeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(120))
            guard !Task.isCancelled, let self, self.pendingRunId == runId else { return }
            self.clearPendingRun()
            self.report(DantaIntelligenceTransportError.replyTimedOut, operation: .send)
        }
        let message = DantaIntelligenceMessage(
            from: .user, content: text, messageId: "message-\(runId)",
            channelId: channelId ?? 0, timestamp: Int64(Date().timeIntervalSince1970 * 1000))
        messages.append(message)
        unconfirmedMessageIds.insert(message.id)
        input = ""
        defer { if loadGeneration == generation { isSending = false } }
        do {
            try await transport.sendMessage(channelId: channelId, message: text, idempotencyKey: runId)
        } catch {
            guard loadGeneration == generation else { return }
            if pendingRunId == runId { clearPendingRun() }
            report(error, operation: .send)
        }
    }

    private func handle(_ event: DantaIntelligenceChatTransportEvent) {
        guard !isPaused else { return }
        switch event {
        case .connectionState(let state):
            connectionState = state
            switch state {
            case .ready:
                clearIssue(for: .connect)
                if !isLoading {
                    refreshHistoryAfterRun()
                    Task { [weak self] in await self?.loadSessions() }
                }
            case .failed(let error):
                report(error, operation: .connect)
            default:
                break
            }
        case .accepted(let runId, let channelId):
            if runId == pendingRunId { adoptSession(channelId) }
        case .message(let runId, let message):
            let isOurRun = runId == pendingRunId
            if isOurRun { adoptSession(message.channelId) }
            guard message.channelId == channelId || isOurRun, !message.from.isUser else { return }
            if isOurRun {
                if !messages.contains(where: { $0.id == message.id }) { messages.append(message) }
                unconfirmedMessageIds.insert(message.id)
                clearIssue(for: .send)
                clearPendingRun()
            }
            refreshHistoryAfterRun()
        case .failure(let runId, let error):
            guard runId == pendingRunId else { return }
            report(error, operation: .send)
            clearPendingRun()
            refreshHistoryAfterRun()
        }
    }

    private func adoptSession(_ channelId: Int) {
        guard channelId > 0, self.channelId == nil else { return }
        self.channelId = channelId
        if !sessions.contains(where: { $0.id == channelId }) { placeholderSessionId = channelId }
    }

    private func history(for channelId: Int?) async throws -> [DantaIntelligenceMessage] {
        guard let channelId else { return [] }
        let messages = try await DantaIntelligenceAPI.listMessages(channelId: channelId, sort: "asc", size: 100)
        var seen = Set<String>()
        return messages.filter { seen.insert($0.id).inserted }.map { message in
            guard message.from.isUser else { return message }
            return DantaIntelligenceMessage(
                from: message.from,
                content: DantaIntelligenceTextProcessing.preprocessMarkdown(message.content).cleaned,
                messageId: message.id, taskId: message.taskId,
                channelId: message.channelId, timestamp: message.timestamp)
        }
    }

    private func retriedHistory(for channelId: Int?) async throws -> [DantaIntelligenceMessage] {
        try await DantaIntelligenceRetry.perform(
            operation: .history,
            deadline: ContinuousClock.now.advanced(by: .seconds(30))) { [self] in
                try await history(for: channelId)
            }
    }

    private func refreshHistoryAfterRun() {
        let generation = loadGeneration
        let channelId = channelId
        historyTask?.cancel()
        historyTask = Task { [weak self] in
            guard let self else { return }
            do {
                let incoming = try await retriedHistory(for: channelId)
                guard loadGeneration == generation, !Task.isCancelled, !isLoading else { return }
                mergeHistory(incoming)
                clearIssue(for: .history)
            } catch {
                guard loadGeneration == generation, !Task.isCancelled, !isLoading else { return }
                report(error, operation: .history, background: true)
            }
        }
    }

    private func mergeHistory(_ incoming: [DantaIntelligenceMessage]) {
        guard !incoming.isEmpty else { return }
        let previousIds = Set(messages.map(\.id))
        let incomingIds = Set(incoming.map(\.id))
        unconfirmedMessageIds.subtract(incomingIds)
        // Some servers assign another ID to the echoed user message. Match new history
        // entries once, in order, so repeated messages with the same text stay distinct.
        var unmatchedUsers = incoming.filter { $0.from.isUser && !previousIds.contains($0.id) }
        var merged = incoming
        for message in messages where unconfirmedMessageIds.contains(message.id) {
            if message.from.isUser,
               let index = unmatchedUsers.firstIndex(where: {
                   $0.content == DantaIntelligenceTextProcessing.preprocessMarkdown(message.content).cleaned
               }) {
                unmatchedUsers.remove(at: index)
                unconfirmedMessageIds.remove(message.id)
                continue
            }
            let index = merged.firstIndex { $0.timestamp > message.timestamp } ?? merged.endIndex
            merged.insert(message, at: index)
        }
        messages = merged
    }

    private func clearPendingRun() {
        pendingRunId = nil
        replyTimeoutTask?.cancel()
        replyTimeoutTask = nil
    }

    private func clearIssue(for operation: DantaIntelligenceError.Operation) {
        if issue?.operation == operation { issue = nil }
    }

    private func report(
        _ error: Error,
        operation: DantaIntelligenceError.Operation,
        background: Bool = false
    ) {
        guard !DantaIntelligenceError.isCancellation(error) else { return }
        let failure = DantaIntelligenceError(error, operation: operation)
        if issue?.requiresLogin == true, !failure.requiresLogin { return }
        if failure.requiresLogin {
            issue = failure
            return
        }
        // Recovery does not establish whether an interrupted message was delivered.
        if issue?.operation == .send, operation != .send { return }
        if background, issue != nil { return }
        issue = failure
    }
}
