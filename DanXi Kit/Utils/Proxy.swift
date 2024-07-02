import Foundation
import FudanKit
import KeychainAccess
import SwiftUI

public class Proxy {
    public static let shared = Proxy()
    
    let authenticator = ProxyAuthenticator()
    public var outsideCampus = false
    
    public var shouldTryProxy: Bool {
        ProxySettings.shared.enableProxy && FudanKit.CredentialStore.shared.credentialPresent
    }
    
    func upload(for request: URLRequest, from bodyData: Data) async throws -> (Data, URLResponse) {
        guard shouldTryProxy, outsideCampus else {
            return try await URLSession.shared.upload(for: request, from: bodyData)
        }
        
        let proxiedRequest = createProxiedRequest(request: request)
        // we do not try to relogin here, because it's highly unlikely to fail
        return try await URLSession.shared.upload(for: proxiedRequest, from: bodyData)
    }
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard shouldTryProxy else {
            return try await URLSession.shared.data(for: request)
        }
        
        // try direct request once
        if !outsideCampus {
            do {
                let config = URLSessionConfiguration.default
                config.timeoutIntervalForRequest = 2.0
                let session = URLSession(configuration: config)
                return try await session.data(for: request)
            } catch URLError.timedOut {
                outsideCampus = true
            }
        }
        
        // use proxy
        try await authenticator.tryAuthenticate()
        
        let proxiedRequest = createProxiedRequest(request: request)
        let (data, response) = try await URLSession.shared.data(for: proxiedRequest)
        if let responseURL = response.url,
           !responseURL.path().hasPrefix("/login") {
            return (data, response) // successful return
        }
        
        // unauthorized, try login WebVPN
        try await authenticator.reauthenticate()
        return try await URLSession.shared.data(for: proxiedRequest)
    }
    
    public func createProxiedURL(url: URL) -> URL {
        guard let host = url.host else {
            return url
        }
        
        let proxiedURLString: String
        switch host {
        case "forum.fduhole.com":
            let path = url.absoluteString.trimmingPrefix("https://forum.fduhole.com")
            proxiedURLString = "https://webvpn.fudan.edu.cn/https/77726476706e69737468656265737421f6f853892a7e6e546b0086a09d1b203a46" + path
        case "auth.fduhole.com":
            let path = url.absoluteString.trimmingPrefix("https://auth.fduhole.com")
            proxiedURLString = "https://webvpn.fudan.edu.cn/https/77726476706e69737468656265737421f1e2559469366c45760785a9d6562c38" + path
        case "danke.fduhole.com":
            let path = url.absoluteString.trimmingPrefix("https://danke.fduhole.com")
            proxiedURLString = "https://webvpn.fudan.edu.cn/https/77726476706e69737468656265737421f4f64f97227e6e546b0086a09d1b203a73" + path
        case "image.fduhole.com":
            let path = url.absoluteString.trimmingPrefix("https://image.fduhole.com")
            proxiedURLString = "https://webvpn.fudan.edu.cn/https/77726476706e69737468656265737421f9fa409b227e6e546b0086a09d1b203ab8" + path
        default:
            return url
        }
        
        guard let proxiedURL = URL(string: proxiedURLString) else {
            return url
        }
        
        return proxiedURL
    }
    
    private func createProxiedRequest(request: URLRequest) -> URLRequest {
        guard let url = request.url else {
            return request
        }

        let proxiedURL = createProxiedURL(url: url)

        var proxiedRequest = URLRequest(url: proxiedURL)
        proxiedRequest.allHTTPHeaderFields = request.allHTTPHeaderFields
        proxiedRequest.httpMethod = request.httpMethod
        proxiedRequest.httpBody = request.httpBody
        return proxiedRequest
    }
}

/// An authenticator for WebVPN service to prevent race conditions
actor ProxyAuthenticator {
    var isLogged = false
    var authenticationTask: Task<Void, Error>? = nil
    var reauthenticationTask: Task<Void, Error>? = nil
    
    /// Pre-authenticate before every request
    func tryAuthenticate() async throws {
        if isLogged { return }
        
        if let authenticationTask {
            try await authenticationTask.value
            return
        }
        
        let task = Task {
            let loginURL = URL(string: "https://webvpn.fudan.edu.cn/login?cas_login=true")!
            let tokenURL = try await FudanKit.AuthenticationAPI.authenticateForURL(loginURL)
            _ = try await URLSession.shared.data(from: tokenURL)
        }
        authenticationTask = task
        try await task.value
        isLogged = true
    }
    
    /// Re-authenticate when some request failed due to unauthorized error
    func reauthenticate() async throws {
        isLogged = false
        
        if let reauthenticationTask {
            try await reauthenticationTask.value
            isLogged = true
            return
        }
        
        let task = Task {
            let loginURL = URL(string: "https://webvpn.fudan.edu.cn/login?cas_login=true")!
            let tokenURL = try await FudanKit.AuthenticationAPI.authenticateForURL(loginURL)
            _ = try await URLSession.shared.data(from: tokenURL)
        }
        reauthenticationTask = task
        try await task.value
        isLogged = true
    }
}

public class ProxySettings: ObservableObject {
    public static let shared = ProxySettings()
    
    @AppStorage("enable-proxy") public var enableProxy = true
}
