import Foundation

/// Keeps the cause intact until the presentation boundary chooses a recovery message.
public struct DantaIntelligenceError: LocalizedError {
    public enum Operation: Sendable {
        case status, setup, start, stop, restart, reset, connect, history, send

        var failureDescription: String {
            switch self {
            case .status: String(localized: "Unable to check the instance status.", bundle: .module)
            case .setup: String(localized: "Unable to set up Danta Intelligence.", bundle: .module)
            case .start: String(localized: "Unable to start the instance.", bundle: .module)
            case .stop: String(localized: "Unable to stop the instance.", bundle: .module)
            case .restart: String(localized: "Unable to restart the instance.", bundle: .module)
            case .reset: String(localized: "Unable to reset the instance.", bundle: .module)
            case .connect: String(localized: "Unable to connect to Danta Intelligence.", bundle: .module)
            case .history: String(localized: "Unable to load conversations.", bundle: .module)
            case .send: String(localized: "Unable to send the message.", bundle: .module)
            }
        }
    }

    public let underlying: any Error
    public let operation: Operation

    public init(_ error: any Error, operation: Operation) {
        self.underlying = (error as? Self)?.underlying ?? error
        self.operation = operation
    }

    public static func isCancellation(_ error: any Error) -> Bool {
        if let error = error as? Self { return isCancellation(error.underlying) }
        return error is CancellationError || (error as? URLError)?.code == .cancelled
    }

    public static var transitionTimedOut: Self {
        Self(DantaIntelligenceTransportError.transitionTimedOut, operation: .status)
    }

    private var statusCode: Int? {
        (underlying as? DantaIntelligenceRemoteError)?.statusCode ?? (underlying as? HTTPError)?.code
    }

    public var requiresLogin: Bool {
        underlying is TokenError || statusCode == 401
            || (underlying as? DantaIntelligenceRemoteError)?.code == "AUTH_001"
    }

    /// A definitive response may be followed by a new operation with a new identifier.
    public var isDefinitive: Bool {
        let remote = underlying as? DantaIntelligenceRemoteError
        guard let statusCode else { return remote != nil }
        return remote?.code != nil || (400..<500).contains(statusCode) && statusCode != 408 && statusCode != 429
    }

    public var errorDescription: String? {
        [reason, recoverySuggestion].compactMap { $0 }.joined(separator: " ")
    }

    private var reason: String {
        if requiresLogin {
            return String(localized: "Your login has expired.", bundle: .module)
        }
        if let error = underlying as? URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost:
                return String(localized: "Danta Intelligence could not be reached.", bundle: .module)
            case .timedOut:
                return String(localized: "The Danta Intelligence request timed out.", bundle: .module)
            default: break
            }
        }
        if underlying is DecodingError {
            return String(localized: "Danta Intelligence returned an invalid response.", bundle: .module)
        }
        let http = underlying as? HTTPError
        let remote = underlying as? DantaIntelligenceRemoteError
        switch remote?.code {
        case "CLAW_001":
            return String(localized: "Your OpenClaw instance is not ready.", bundle: .module)
        case "INVALID_IDEMPOTENCY_KEY", "INVALID_ONBOARD_PAYLOAD":
            return String(localized: "Danta Intelligence could not process this request.", bundle: .module)
        default: break
        }
        if statusCode == 403 {
            return String(localized: "You do not have permission to perform this operation.", bundle: .module)
        }
        let message = (remote?.message ?? http?.message)?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let message {
            if message.isEmpty || message.lowercased() == "provider operation failed" {
                return operation.failureDescription
            }
            return "\(operation.failureDescription) \(message)"
        }
        if let error = underlying as? DantaIntelligenceTransportError {
            return error.localizedDescription
        }
        return operation.failureDescription
    }

    public var recoverySuggestion: String? {
        if requiresLogin {
            return String(localized: "Please sign in again, then retry.", bundle: .module)
        }
        if operation == .send {
            return String(localized: "Refresh the conversation to check whether it was received before sending again.", bundle: .module)
        }
        if let error = underlying as? URLError, error.code != .timedOut {
            return String(localized: "Check your connection, then retry.", bundle: .module)
        }
        switch operation {
        case .setup, .start, .stop, .restart, .reset:
            return String(localized: "Refresh the instance status before trying again.", bundle: .module)
        default:
            return String(localized: "Please try again in a moment.", bundle: .module)
        }
    }
}

public enum DantaIntelligenceTransportError: Error, LocalizedError {
    case notConnected
    case invalidSession
    case duplicateRequest(String)
    case requestTimedOut(String)
    case unexpectedResponse(expected: String, received: String)
    case instanceNotReady(String)
    case transitionTimedOut
    case replyTimedOut

    public var errorDescription: String? {
        switch self {
        case .notConnected:
            String(localized: "Danta Intelligence is not connected.", bundle: .module)
        case .invalidSession:
            String(localized: "This conversation is no longer available.", bundle: .module)
        case .duplicateRequest:
            String(localized: "This request is already in progress.", bundle: .module)
        case .requestTimedOut:
            String(localized: "The Danta Intelligence request timed out.", bundle: .module)
        case .unexpectedResponse:
            String(localized: "Danta Intelligence returned an unexpected response.", bundle: .module)
        case .instanceNotReady:
            String(localized: "Your OpenClaw instance is not ready.", bundle: .module)
        case .transitionTimedOut:
            String(localized: "The instance operation is taking longer than expected.", bundle: .module)
        case .replyTimedOut:
            String(localized: "No reply was received. Refresh the conversation before sending again.", bundle: .module)
        }
    }
}
