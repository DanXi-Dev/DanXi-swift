import Foundation

/// Bounded retry for reads and connection recovery. Never use this to resend chat messages.
public enum DantaIntelligenceRetry {
    public static let delays: [Duration] = [.seconds(1), .seconds(3), .seconds(6)]

    public static func perform<T: Sendable>(
        operation: DantaIntelligenceError.Operation,
        deadline: ContinuousClock.Instant,
        shouldRetry: (@Sendable (DantaIntelligenceError) async -> Bool)? = nil,
        action: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let clock = ContinuousClock()
        let timeout = DantaIntelligenceError(
            DantaIntelligenceTransportError.requestTimedOut("recovery"), operation: operation)
        for attempt in 0...delays.count {
            try Task.checkCancellation()
            guard clock.now < deadline else { throw timeout }
            do {
                let result = try await withDeadline(deadline: deadline, timeout: timeout, action: action)
                try Task.checkCancellation()
                guard clock.now < deadline else { throw timeout }
                return result
            } catch {
                try Task.checkCancellation()
                if DantaIntelligenceError.isCancellation(error) { throw error }
                guard clock.now < deadline else { throw timeout }
                let failure = DantaIntelligenceError(error, operation: operation)
                guard attempt < delays.count, failure.isAutoRetryable else { throw failure }
                if let shouldRetry {
                    let retry = try await withDeadline(deadline: deadline, timeout: timeout) {
                        await shouldRetry(failure)
                    }
                    guard retry else { throw failure }
                }
                // A single absolute deadline includes every request and backoff.
                let wake = min(clock.now.advanced(by: delays[attempt]), deadline)
                try await clock.sleep(until: wake)
            }
        }
        throw timeout
    }

    static func withDeadline<T: Sendable>(
        deadline: ContinuousClock.Instant,
        timeout: DantaIntelligenceError,
        action: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let task = Task { try await action() }
        // Unlike a shared transport task, this attempt belongs to this caller.
        // Cancel it on timeout as well as cancellation, without awaiting cooperation.
        defer { task.cancel() }
        return try await DantaIntelligenceTaskWaiter<T>.value(
            of: task, deadline: deadline, timeoutError: timeout)
    }
}

/// Waits for a shared task without letting one caller cancel that task or hang
/// behind an operation which does not cooperate with Swift task cancellation.
final class DantaIntelligenceTaskWaiter<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<T, Error>?
    private var resolution: Result<T, Error>?
    private var tasks: [Task<Void, Never>] = []

    static func value(
        of task: Task<T, Error>,
        deadline: ContinuousClock.Instant,
        timeoutError: any Error
    ) async throws -> T {
        try Task.checkCancellation()
        guard ContinuousClock().now < deadline else { throw timeoutError }
        let waiter = DantaIntelligenceTaskWaiter<T>()
        let value: T = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T, Error>) in
                guard waiter.install(continuation) else { return }
                waiter.track(Task.detached { [weak waiter] in
                    let result = await task.result
                    waiter?.resolve(result)
                })
                waiter.track(Task.detached { [weak waiter] in
                    do {
                        try await ContinuousClock().sleep(until: deadline)
                        waiter?.resolve(.failure(timeoutError))
                    } catch {
                        // The result or caller cancellation already resolved this wait.
                    }
                })
            }
        } onCancel: {
            waiter.resolve(.failure(CancellationError()))
        }
        try Task.checkCancellation()
        guard ContinuousClock().now < deadline else { throw timeoutError }
        return value
    }

    private func install(_ continuation: CheckedContinuation<T, Error>) -> Bool {
        lock.lock()
        if let resolution {
            lock.unlock()
            continuation.resume(with: resolution)
            return false
        }
        self.continuation = continuation
        lock.unlock()
        return true
    }

    private func track(_ task: Task<Void, Never>) {
        lock.lock()
        let resolved = resolution != nil
        if !resolved { tasks.append(task) }
        lock.unlock()
        if resolved { task.cancel() }
    }

    private func resolve(_ resolution: Result<T, Error>) {
        lock.lock()
        guard self.resolution == nil else {
            lock.unlock()
            return
        }
        self.resolution = resolution
        let continuation = continuation
        self.continuation = nil
        let tasks = tasks
        self.tasks = []
        lock.unlock()
        tasks.forEach { $0.cancel() }
        continuation?.resume(with: resolution)
    }
}
