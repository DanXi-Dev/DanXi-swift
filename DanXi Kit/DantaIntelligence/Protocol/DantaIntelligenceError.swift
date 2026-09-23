import Foundation

/// Retains the cause for diagnostics and uses the same message across operations.
public struct DantaIntelligenceError: LocalizedError, Sendable {
    public enum Operation: String, Sendable {
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

    /// Classify the underlying cause once without conflating a rejected request with
    /// a lost connection or with an operation whose delivery is uncertain.
    private enum Cause {
        case token
        case remote(DantaIntelligenceRemoteError)
        case http(Int)
        case network(URLError.Code)
        case transport(DantaIntelligenceTransportError)
        case other
    }

    private var cause: Cause {
        switch underlying {
        case is TokenError: return .token
        case let error as DantaIntelligenceRemoteError: return .remote(error)
        case let error as HTTPError: return .http(error.code)
        case let error as URLError: return .network(error.code)
        case let error as DantaIntelligenceTransportError: return .transport(error)
        default: return .other
        }
    }

    private var statusCode: Int? {
        switch cause {
        case .remote(let error): return error.statusCode
        case .http(let code): return code
        default: return nil
        }
    }

    public var requiresLogin: Bool {
        if case .token = cause { return true }
        return statusCode == 401
    }

    /// Keep the request identifier when the outcome is still uncertain.
    public var isDefinitive: Bool {
        if case .remote(let error) = cause {
            guard let statusCode = error.statusCode else { return true }
            return error.code != nil || Self.isDefinitiveStatus(statusCode)
        }
        return statusCode.map(Self.isDefinitiveStatus) ?? false
    }

    private static func isDefinitiveStatus(_ statusCode: Int) -> Bool {
        (400..<500).contains(statusCode) && statusCode != 408 && statusCode != 429
    }

    /// A definitive rejection can still be transient. This is intentionally
    /// independent of whether an earlier request may already have taken effect.
    public var isAutoRetryable: Bool {
        if case .transport(.authenticationRejected) = cause { return false }
        return !requiresLogin && statusCode != 403
    }

    var isInstanceNotReady: Bool {
        switch cause {
        case .remote(let error): return error.code == "CLAW_001"
        case .transport(.instanceNotReady): return true
        default: return false
        }
    }

    public var isReachabilityFailure: Bool {
        switch cause {
        case .network, .transport(.notConnected): return true
        default: return false
        }
    }

    public var errorDescription: String? {
        if requiresLogin {
            return String(localized: "Please sign in again to use Danta Intelligence.", bundle: .module)
        }
        if statusCode == 403 {
            return String(localized: "You do not have permission to perform this operation.", bundle: .module)
        }
        switch cause {
        case .network(.timedOut), .transport(.requestTimedOut), .transport(.transitionTimedOut):
            return Self.timedOut
        case .network, .transport(.notConnected):
            return Self.unreachable
        case .remote(let error) where error.code == "AUTH_001":
            return String(localized: "Danta Intelligence connection authentication failed. Please retry.", bundle: .module)
        case .transport(.authenticationRejected):
            return String(localized: "Danta Intelligence connection authentication failed. Please retry.", bundle: .module)
        case .remote(let error) where error.code == "CLAW_001":
            return Self.instanceNotReady
        case .transport(.instanceNotReady):
            return Self.instanceNotReady
        case .transport(.replyTimedOut):
            return String(localized: "No reply was received. Refresh the conversation before sending again.", bundle: .module)
        case .transport(.deliveryUncertain):
            return String(localized: "Connection interrupted. Refresh the conversation before sending again.", bundle: .module)
        default:
            return String(localized: "Danta Intelligence could not complete the request. Please try again later.", bundle: .module)
        }
    }

    /// Safe to log: never includes server messages, request identifiers, or tokens.
    public var diagnosticDescription: String {
        let detail: String
        switch cause {
        case .token: detail = "token"
        case .remote(let error):
            let code = error.code.flatMap { code in
                code.range(of: #"^[A-Z]{2,12}_[0-9]{3}$"#, options: .regularExpression) == nil ? nil : code
            } ?? "other"
            detail = "remote code=\(code) status=\(error.statusCode.map(String.init) ?? "none")"
        case .http(let code): detail = "http status=\(code)"
        case .network(let code): detail = "network code=\(code.rawValue)"
        case .transport(let error):
            switch error {
            case .notConnected: detail = "notConnected"
            case .invalidSession: detail = "invalidSession"
            case .duplicateRequest: detail = "duplicateRequest"
            case .requestTimedOut: detail = "requestTimedOut"
            case .unexpectedResponse: detail = "unexpectedResponse"
            case .instanceNotReady: detail = "instanceNotReady"
            case .transitionTimedOut: detail = "transitionTimedOut"
            case .replyTimedOut: detail = "replyTimedOut"
            case .deliveryUncertain: detail = "deliveryUncertain"
            case .authenticationRejected(let code): detail = "authRejected status=\(code)"
            }
        case .other: detail = "other"
        }
        return "operation=\(operation.rawValue) \(detail)"
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
    case deliveryUncertain
    case authenticationRejected(Int)
}
