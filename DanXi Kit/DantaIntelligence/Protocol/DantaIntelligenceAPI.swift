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
        var request = URLRequest(url: url)
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
