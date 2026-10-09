import DanXiKit
import Foundation
import Observation

@MainActor
@Observable
@available(iOS 18.0, *)
final class DantaIntelligenceViewModel {
    enum Phase: Equatable {
        case checking
        case preparing(DantaIntelligenceInstanceState)
        case ready
        case inactive(DantaIntelligenceInstanceState)
        case failed
    }

    enum Operation: Equatable {
        case checking, setup, lifecycle(DantaIntelligenceLifecycleAction)

        var targetState: DantaIntelligenceInstanceState? {
            switch self {
            case .checking: nil
            case .setup, .lifecycle(.start), .lifecycle(.restart): .ready
            case .lifecycle(.stop): .stopped
            case .lifecycle(.reset): .notStarted
            }
        }
    }

    private struct PendingOperation {
        let operation: Operation
        let key: String
        var acknowledged = false
    }

    @ObservationIgnored private let transport: DantaIntelligenceChatTransport
    @ObservationIgnored private var pendingOperation: PendingOperation?
    private(set) var operation: Operation?
    private(set) var instanceStatus: DantaIntelligenceInstanceStatus?
    private(set) var readiness: DantaIntelligenceLifecycleReadiness?
    private(set) var issue: DantaIntelligenceError?
    let chat: DantaChatViewModel

    init() {
        let transport = DantaIntelligenceChatTransport()
        self.transport = transport
        self.chat = DantaChatViewModel(transport: transport)
    }

    var instanceState: DantaIntelligenceInstanceState? { instanceStatus?.state }
    var isBusy: Bool { operation != nil }
    var isReady: Bool { phase == .ready }

    var phase: Phase {
        if let operation, operation != .checking {
            switch operation {
            case .setup: return .preparing(instanceState ?? .provisioning)
            case .lifecycle(let action): return .preparing(action.transitionState)
            case .checking: break
            }
        }
        guard let state = instanceState else { return issue == nil ? .checking : .failed }
        if state.isReady { return .ready }
        if state.isTransitioning, isBusy { return .preparing(state) }
        return .inactive(state)
    }

    var previousInstanceIssue: DantaIntelligenceError? {
        guard let status = instanceStatus else { return nil }
        let code = status.lastErrorCode ?? status.cleanupErrorCode
        let message = status.lastErrorMessage ?? status.cleanupErrorMessage ?? ""
        guard code != nil || !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return DantaIntelligenceError(
            DantaIntelligenceRemoteError(code: code, message: message), operation: .instance)
    }

    func refreshInstanceStatus() async {
        guard !isBusy else { return }
        operation = .checking
        defer { operation = nil }
        let deadline = ContinuousClock.now.advanced(by: .seconds(120))
        do {
            let status = try await DantaIntelligenceRetry.perform(
                operation: .instance,
                deadline: deadline) { [self] in
                    try await waitForStatus(deadline: deadline)
                }
            try Task.checkCancellation()
            issue = nil
            await reconcilePending(with: status)
        } catch {
            guard !DantaIntelligenceError.isCancellation(error) else { return }
            instanceStatus = nil
            readiness = nil
            issue = DantaIntelligenceError(error, operation: .instance)
        }
    }

    func setup() async {
        guard !isBusy, instanceState == .notStarted else { return }
        await perform(.setup)
    }

    func canPerform(_ action: DantaIntelligenceLifecycleAction) -> Bool {
        guard !isBusy, let state = instanceState else { return false }
        switch action {
        case .start: return state == .stopped || state == .failed
        case .stop, .restart: return state.isReady
        case .reset: return state != .notStarted && !state.isTransitioning
        }
    }

    func performLifecycleAction(_ action: DantaIntelligenceLifecycleAction) async {
        guard canPerform(action) else { return }
        await perform(.lifecycle(action))
    }

    private func perform(_ operation: Operation) async {
        self.operation = operation
        readiness = nil
        defer { self.operation = nil }
        // Keep the key when delivery was uncertain, even across a status refresh.
        if pendingOperation?.operation != operation {
            pendingOperation = PendingOperation(operation: operation, key: UUID().uuidString)
        }
        guard let pending = pendingOperation else { return }
        let deadline = ContinuousClock.now.advanced(by: operation == .setup ? .seconds(900) : .seconds(120))
        do {
            if !pending.acknowledged {
                switch operation {
                case .setup:
                    let status = try await transport.onboard(requestId: pending.key)
                    pendingOperation?.acknowledged = true
                    try Task.checkCancellation()
                    await apply(status)
                case .lifecycle(let action):
                    let result = try await DantaIntelligenceAPI.performLifecycleAction(action, idempotencyKey: pending.key)
                    pendingOperation?.acknowledged = true
                    try Task.checkCancellation()
                    readiness = result.readiness
                    if result.operation.status.lowercased() == "failed" {
                        throw DantaIntelligenceRemoteError(code: nil, message: "")
                    }
                case .checking: return
                }
            }
            let status = try await waitForStatus(deadline: deadline, targetState: operation.targetState)
            issue = nil
            await reconcilePending(with: status)
        } catch {
            guard !DantaIntelligenceError.isCancellation(error) else { return }
            let failure = DantaIntelligenceError(error, operation: .instance)
#if DEBUG
            print("[DantaIntelligence] \(failure.diagnosticDescription)")
#endif
            issue = failure
            if failure.isDefinitive { pendingOperation = nil }
            // Refresh the snapshot without masking the operation's failure.
            do {
                let status = try await DantaIntelligenceAPI.instanceStatus()
                try Task.checkCancellation()
                await apply(status)
                await reconcilePending(with: status)
            } catch { /* Keep the last known state and the initiating error. */ }
        }
    }

    private func waitForStatus(
        deadline: ContinuousClock.Instant, targetState: DantaIntelligenceInstanceState? = nil
    ) async throws -> DantaIntelligenceInstanceStatus {
        while true {
            try Task.checkCancellation()
            guard ContinuousClock.now < deadline else {
                throw DantaIntelligenceTransportError.transitionTimedOut
            }
            let status = try await DantaIntelligenceAPI.instanceStatus()
            try Task.checkCancellation()
            await apply(status)
            if !status.state.isTransitioning,
               targetState == nil || status.state == targetState || status.state == .failed {
                return status
            }
            let remaining = ContinuousClock.now.duration(to: deadline)
            guard remaining > .zero else {
                throw DantaIntelligenceTransportError.transitionTimedOut
            }
            try await Task.sleep(for: min(.seconds(2), remaining))
        }
    }

    private func apply(_ status: DantaIntelligenceInstanceStatus) async {
        let wasReady = instanceState?.isReady == true
        if instanceState != status.state { readiness = nil }
        instanceStatus = status
        if status.state.isReady {
            if !wasReady {
                chat.refresh()
            }
        } else if wasReady {
            chat.pause()
            await transport.disconnect()
        }
    }

    private func reconcilePending(with status: DantaIntelligenceInstanceStatus) async {
        guard let pending = pendingOperation, !status.state.isTransitioning else { return }
        if pending.operation.targetState == nil || status.state == pending.operation.targetState {
            pendingOperation = nil
            issue = nil
            if pending.operation == .lifecycle(.reset) {
                chat.resetForDeletedInstance()
                readiness = nil
                await transport.disconnect()
            }
        } else if pending.acknowledged, status.state == .failed {
            pendingOperation = nil
            issue = previousInstanceIssue ?? DantaIntelligenceError(
                DantaIntelligenceRemoteError(code: nil, message: ""), operation: .instance)
        }
    }
}

private extension DantaIntelligenceLifecycleAction {
    var transitionState: DantaIntelligenceInstanceState {
        switch self {
        case .start, .restart: .starting
        case .stop: .stopping
        case .reset: .resetting
        }
    }
}
