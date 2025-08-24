import Foundation
import Utils
import Queue

/// An actor that coordinates Single Sign-On (SSO) authentication against a
/// central authorization server and fetching from business services that may
/// redirect to that server when unauthenticated.
public actor Authenticator {
    // MARK: - State

    /// A mutex-like task reference for serializing login attempts.
    private var task: Task<(), Never>?

    /// Cache of last successful *business host* login time. Used as a soft TTL
    /// (2 hours) to avoid hitting the auth center on every request.
    private var loginStatus: [String: Date]

    /// Caller-supplied login routine that performs the SSO flow *against the
    /// authorization center* using the provided `loginURL`.
    let authenticationAPI: (_ loginURL: URL) async throws -> (Data, URLResponse)

    /// How long a successful login is considered valid for a given business host.
    private let loginValidity: TimeInterval = 2 * 60 * 60 // 2 hours

    // MARK: - Init

    init(authenticationAPI: @escaping (_ loginURL: URL) async throws -> (Data, URLResponse)) {
        self.authenticationAPI = authenticationAPI
        self.loginStatus = [:]
        self.task = nil
    }

    // MARK: - Public API

    public func authenticateRequest(request: URLRequest) async throws -> (Data, URLResponse) {
        guard let url = request.url, let host = url.host() else { throw LocatableError() }

        if isLogged(host: host), let direct = try await directFetch(request: request) {
            return direct
        }
        
        _ = try await performAuthenticate(url: url)

        if let retried = try await directFetch(request: request) {
            return retried
        }

        throw CampusError.loginFailed
    }

    public func authenticateRequest(request: URLRequest, loginURL: URL) async throws -> (Data, URLResponse) {
        guard let host = request.url?.host else { throw LocatableError() }
        
        if !isLogged(host: host) {
            _ = try await performAuthenticate(url: loginURL)
        }
        
        if let retried = try await directFetch(request: request) {
            return retried
        }

        throw CampusError.loginFailed
    }

    // MARK: - Internals

    private func isLogged(host: String) -> Bool {
        guard let last = loginStatus[host] else { return false }
        return Date().timeIntervalSince(last) < loginValidity
    }

    private func withSerialTask<T>(operation: @escaping () async throws -> T) async throws -> T {
        if let task = self.task { await task.value }
        let t = Task { try await operation() }
        self.task = Task { _ = try? await t.value }
        defer { self.task = nil }
        return try await t.value
    }

    /// Perform the SSO login against the authorization center.
    private func performAuthenticate(url: URL) async throws -> (Data, URLResponse) {
        guard let host = url.host() else { throw LocatableError() }
        
        let (data, response) = try await withSerialTask {
            try await self.authenticationAPI(url)
        }

        guard response.url?.host == host else {
            throw CampusError.loginFailed
        }
        self.loginStatus[host] = Date()
        return (data, response)
    }

    
    private func directFetch(request: URLRequest) async throws -> (Data, URLResponse)? {
        guard let requestHost = request.url?.host else { throw LocatableError() }

        let (data, response) = try await URLSession.campusSession.data(for: request)

        if response.url?.host == requestHost {
            return (data, response)
        }
        return nil
    }
}

// MARK: - Instances

extension Authenticator {
    public static let classic = Authenticator { loginURL in
        try await AuthenticationAPI.authenticate(loginURL)
    }
    
    public static let neo = Authenticator { loginURL in
        try await NeoAuthenticationAPI.authenticate(loginURL)
    }
}

// MARK: - Convenient Wrappers

extension Authenticator {
    public func authenticate(_ url: URL, loginURL: URL? = nil) async throws -> Data {
        let request = constructRequest(url)
        
        return if let loginURL {
            try await authenticateRequest(request: request, loginURL: loginURL).0
        } else {
            try await authenticateRequest(request: request).0
        }
    }
    
    public func authenticate(_ request: URLRequest, loginURL: URL? = nil) async throws -> Data {
        if let loginURL {
            try await authenticateRequest(request: request, loginURL: loginURL).0
        } else {
            try await authenticateRequest(request: request).0
        }
    }
}
