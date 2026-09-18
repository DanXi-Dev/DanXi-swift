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
    private(set) var isCheckingConnection = false
    private(set) var healthOK = false
    private(set) var issue: DantaIntelligenceError?
    private(set) var sessionsIssue: DantaIntelligenceError?
    private var pendingRunId: String?

    @ObservationIgnored private let transport: DantaIntelligenceChatTransport
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private nonisolated(unsafe) var eventTask: Task<Void, Never>?
    @ObservationIgnored private nonisolated(unsafe) var replyTimeoutTask: Task<Void, Never>?
    private var loadGeneration = UUID()
    private var sessionsGeneration = UUID()
    private var healthGeneration = UUID()
    private var isPaused = true
    private var lastHealthPollAt: Date?
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
        let transport = transport
        Task { await transport.disconnect() }
    }

    var pendingRunCount: Int { pendingRunId == nil ? 0 : 1 }
    var canSend: Bool {
        healthOK && !isLoading && !isSending && pendingRunId == nil
            && issue?.requiresLogin != true && !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func refresh() {
        loadTask?.cancel()
        loadTask = Task { await bootstrap() }
    }

    func pause() {
        isPaused = true
        loadGeneration = UUID()
        sessionsGeneration = UUID()
        healthGeneration = UUID()
        loadTask?.cancel()
        loadTask = nil
        isLoading = false
        isLoadingSessions = false
        isCheckingConnection = false
        isSending = false
        healthOK = false
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

    private func bootstrap() async {
        guard !Task.isCancelled else { return }
        let generation = UUID()
        loadGeneration = generation
        isPaused = false
        isLoading = true
        healthGeneration = UUID()
        isCheckingConnection = false
        isSending = false
        clearPendingRun()
        let channelId = channelId
        var operation = DantaIntelligenceError.Operation.history
        defer { if loadGeneration == generation { isLoading = false } }
        do {
            // Saved messages can still be read when the live connection is unavailable.
            let history = try await history(for: channelId)
            guard loadGeneration == generation, !Task.isCancelled else { return }
            messages = history
            unconfirmedMessageIds = []
            operation = .connect
            try await transport.connectIfNeeded()
            let ok = try await transport.requestHealth()
            guard loadGeneration == generation, !Task.isCancelled else { return }
            healthOK = ok
            if !ok { throw DantaIntelligenceTransportError.instanceNotReady("") }
            issue = nil
            Task { [weak self] in await self?.loadSessions() }
        } catch {
            guard loadGeneration == generation, !DantaIntelligenceError.isCancellation(error) else { return }
            if operation == .connect { healthOK = false }
            issue = DantaIntelligenceError(error, operation: operation)
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
        case .connectionError(let error):
            healthOK = false
            if !isLoading { report(error, operation: .connect) }
        case .health(let ok):
            healthOK = ok
            if !isLoading, !isCheckingConnection {
                if ok, issue?.operation == .connect { issue = nil }
                if !ok, issue == nil { report(DantaIntelligenceTransportError.notConnected, operation: .connect) }
            }
        case .tick:
            Task { await pollHealth() }
        case .accepted(let runId, let channelId):
            if runId == pendingRunId { adoptSession(channelId) }
        case .message(let runId, let message):
            let isOurRun = runId == pendingRunId
            if isOurRun { adoptSession(message.channelId) }
            guard message.channelId == channelId || isOurRun, !message.from.isUser else { return }
            if isOurRun {
                if !messages.contains(where: { $0.id == message.id }) { messages.append(message) }
                unconfirmedMessageIds.insert(message.id)
                if issue?.operation == .send { issue = nil }
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

    private func refreshHistoryAfterRun() {
        let generation = loadGeneration
        let channelId = channelId
        Task {
            do {
                let incoming = try await history(for: channelId)
                guard loadGeneration == generation, !Task.isCancelled, !isLoading else { return }
                if issue?.operation == .history { issue = nil }
                mergeHistory(incoming)
            } catch {
                guard loadGeneration == generation, !isLoading else { return }
                if issue == nil || DantaIntelligenceError(error, operation: .history).requiresLogin {
                    report(error, operation: .history)
                }
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

    private func pollHealth() async {
        guard !isPaused, !isLoading else { return }
        if isCheckingConnection { return }
        if let lastHealthPollAt, Date().timeIntervalSince(lastHealthPollAt) < 10 { return }
        let generation = UUID()
        healthGeneration = generation
        lastHealthPollAt = Date()
        isCheckingConnection = true
        defer { if healthGeneration == generation { isCheckingConnection = false } }
        do {
            let ok = try await transport.requestHealth()
            guard healthGeneration == generation, !Task.isCancelled else { return }
            healthOK = ok
            if ok {
                if issue?.operation == .connect { issue = nil }
            } else {
                report(DantaIntelligenceTransportError.instanceNotReady(""), operation: .connect)
            }
        } catch {
            guard healthGeneration == generation, !DantaIntelligenceError.isCancellation(error) else { return }
            healthOK = false
            report(error, operation: .connect)
        }
    }

    private func report(_ error: Error, operation: DantaIntelligenceError.Operation) {
        guard !DantaIntelligenceError.isCancellation(error) else { return }
        let failure = DantaIntelligenceError(error, operation: operation)
        if issue?.requiresLogin == true, !failure.requiresLogin { return }
        // Reconnecting does not resolve an uncertain message delivery.
        if issue?.operation == .send, operation == .connect, !failure.requiresLogin { return }
        issue = failure
    }
}
