import Foundation
import Utils

public var dantaIntelligenceURL = URL(string:
    UserDefaults.standard.string(forKey: "danta_intelligence_base_url") ?? "http://127.0.0.1:8000/api/claw")!
public var dantaIntelligenceWebSocketURL = URL(string:
    UserDefaults.standard.string(forKey: "danta_intelligence_ws_url") ?? "ws://127.0.0.1:8000/api/claw/ws")!

public enum DantaIntelligenceAPI {
    public static func instanceStatus() async throws -> DantaIntelligenceInstanceStatus {
        try await request("/instance")
    }

    public static func performLifecycleAction(
        _ action: DantaIntelligenceLifecycleAction,
        idempotencyKey: String
    ) async throws -> DantaIntelligenceLifecycleResult {
        try await request("/\(action.rawValue)", idempotencyKey: idempotencyKey)
    }

    public static func listChannels() async throws -> [DantaIntelligenceChannel] {
        try await request("/channels")
    }

    public static func listMessages(
        channelId: Int,
        sort: String,
        size: Int
    ) async throws -> [DantaIntelligenceMessage] {
        try await request(
            "/messages",
            params: [
                "channel_id": String(channelId),
                "offset": "0",
                "sort": sort,
                "size": String(size)
            ])
    }

    private static func request<Response: Decodable>(
        _ path: String, params: [String: String]? = nil, idempotencyKey: String? = nil
    ) async throws -> Response {
        var url = dantaIntelligenceURL.appendingPathComponent(path)
        if let params {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
            url = components.url!
        }
        // A cached status cannot validate the access token used by the socket.
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.setValue("no-cache, no-store", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        request.httpMethod = idempotencyKey == nil ? "GET" : "POST"
        if let idempotencyKey {
            let key = idempotencyKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else {
                throw DantaIntelligenceRemoteError(code: "INVALID_IDEMPOTENCY_KEY",
                    message: String(localized: "The request identifier cannot be empty.", bundle: .module))
            }
            request.setValue(key, forHTTPHeaderField: "Idempotency-Key")
        }
        let (data, response) = try await Authenticator.shared.authenticate(request: request)
        guard let response = response as? HTTPURLResponse else { throw LocatableError() }
        if response.statusCode >= 300 {
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            throw DantaIntelligenceRemoteError(
                code: json?["error_code"] as? String ?? json?["code"] as? String,
                message: json?["message"] as? String ?? "", statusCode: response.statusCode)
        }
        return try JSONDecoder.defaultDecoder.decode(Response.self, from: data)
    }
}

// WebSocket AUTH_001 does not pass through the HTTP 401 handler.
// Share its refresh task with concurrent HTTP requests.
extension Authenticator {
    func refreshDantaToken(ifRejected access: String) async throws {
        try Task.checkCancellation()
        let deadline = ContinuousClock.now.advanced(by: .seconds(30))
        let task: Task<Void, Error>
        if let refreshTask {
            task = refreshTask
        } else {
            guard let token = CredentialStore.shared.token else { throw TokenError.none }
            guard token.access == access else { return }
            let refresh = token.refresh
            task = Task {
                defer { self.refreshTask = nil }
                try await DantaIntelligenceRetry.withDeadline(
                    deadline: deadline,
                    timeout: DantaIntelligenceError(URLError(.timedOut), operation: .connect)
                ) {
                    try await self.refreshDantaToken(access: access, refresh: refresh, deadline: deadline)
                }
            }
            refreshTask = task
        }
        do {
            try await DantaIntelligenceTaskWaiter<Void>.value(
                of: task, deadline: deadline, timeoutError: URLError(.timedOut))
        } catch let error as HTTPError where error.code == 404 {
            throw DantaIntelligenceTransportError.authenticationRejected(404)
        }
    }

    private func refreshDantaToken(
        access: String, refresh: String, deadline: ContinuousClock.Instant
    ) async throws {
        var request = URLRequest(url: authURL.appending(path: "/refresh"),
                                 cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "POST"
        request.setValue("Bearer \(refresh)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await Proxy.shared.data(for: request)
        try Task.checkCancellation()
        guard ContinuousClock.now < deadline else { throw URLError(.timedOut) }
        // A late response must not replace credentials from a subsequent login.
        guard let current = CredentialStore.shared.token,
              current.access == access, current.refresh == refresh else { throw CancellationError() }
        guard let response = response as? HTTPURLResponse else { throw LocatableError() }
        if response.statusCode == 401 { throw TokenError.expired }
        if response.statusCode == 404 {
            throw DantaIntelligenceTransportError.authenticationRejected(404)
        }
        guard (200..<300).contains(response.statusCode) else { throw HTTPError(code: response.statusCode) }
        CredentialStore.shared.token = try JSONDecoder().decode(Token.self, from: data)
    }
}
