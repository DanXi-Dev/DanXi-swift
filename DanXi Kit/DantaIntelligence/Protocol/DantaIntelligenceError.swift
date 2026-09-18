import Foundation

/// Retains the cause for diagnostics and uses the same message across operations.
public struct DantaIntelligenceError: LocalizedError, Sendable {
    public enum Operation: Sendable {
        case instance, connect, history, send
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

    private var statusCode: Int? {
        (underlying as? DantaIntelligenceRemoteError)?.statusCode ?? (underlying as? HTTPError)?.code
    }

    public var requiresLogin: Bool {
        underlying is TokenError || statusCode == 401
            || (underlying as? DantaIntelligenceRemoteError)?.code == "AUTH_001"
    }

    /// Keep the request identifier when the outcome is still uncertain.
    public var isDefinitive: Bool {
        let remote = underlying as? DantaIntelligenceRemoteError
        guard let statusCode else { return remote != nil }
        return remote?.code != nil || (400..<500).contains(statusCode) && statusCode != 408 && statusCode != 429
    }

    public var errorDescription: String? {
        if requiresLogin {
            return String(localized: "Please sign in again to use Danta Intelligence.", bundle: .module)
        }
        if statusCode == 403 {
            return String(localized: "You do not have permission to perform this operation.", bundle: .module)
        }
        if let error = underlying as? URLError {
            return error.code == .timedOut ? Self.timedOut : Self.unreachable
        }
        if (underlying as? DantaIntelligenceRemoteError)?.code == "CLAW_001" {
            return Self.instanceNotReady
        }
        if let error = underlying as? DantaIntelligenceTransportError {
            switch error {
            case .notConnected: return Self.unreachable
            case .requestTimedOut, .transitionTimedOut: return Self.timedOut
            case .instanceNotReady: return Self.instanceNotReady
            case .replyTimedOut:
                return String(localized: "No reply was received. Refresh the conversation before sending again.", bundle: .module)
            default: break
            }
        }
        return String(localized: "Danta Intelligence could not complete the request. Please try again later.", bundle: .module)
    }

    private static var unreachable: String {
        String(localized: "Danta Intelligence could not be reached.", bundle: .module)
    }

    private static var timedOut: String {
        String(localized: "The Danta Intelligence request timed out.", bundle: .module)
    }

    private static var instanceNotReady: String {
        String(localized: "Your OpenClaw instance is not ready.", bundle: .module)
    }
}

public enum DantaIntelligenceTransportError: Error {
    case notConnected
    case invalidSession
    case duplicateRequest(String)
    case requestTimedOut(String)
    case unexpectedResponse(expected: String, received: String)
    case instanceNotReady(String)
    case transitionTimedOut
    case replyTimedOut
}
