import Foundation
import FudanKit
import KeychainAccess
import SwiftUI

public class Proxy {
    public static let shared = Proxy()
    
    public var outsideCampus = false
    
    public var shouldTryProxy: Bool {
        ProxySettings.shared.enableProxy && FudanKit.CredentialStore.shared.credentialPresent
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        /**
         WebVPN may occasionally return HTML instead of the expected payload; when this occurs, re-authenticate.
         This method can be modified to handle other cases where WebVPN returns unexpected responses.
         */
        
        if let mimeType = response.mimeType, mimeType.contains("text/html") {
            throw WebVPNDisconnectedError()
        }
        if let httpResponse = response as? HTTPURLResponse,
           let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
           contentType.contains("text/html") {
            throw WebVPNDisconnectedError()
        }
    }
    
    func upload(for request: URLRequest, from bodyData: Data) async throws -> (Data, URLResponse) {
        guard shouldTryProxy, outsideCampus else {
            return try await URLSession.shared.upload(for: request, from: bodyData)
        }
        
        let proxiedRequest = createProxiedRequest(request: request)
        // we do not try to relogin here, because it's highly unlikely to fail
        return try await URLSession.shared.upload(for: proxiedRequest, from: bodyData)
        
        // this method is not used yet so no validateResponse check for now
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
            } catch let error as URLError {
                /**
                 The domain fduhole.com and its subdomains are currently mapped to an IP address within the local network.
                 When a user is outside the campus network, they will be unable to connect to fduhole.com directly.
                 There are two possible scenarios:
                 - The IP address associated with fduhole.com does not exist in the user’s network.
                 - The IP address exists and corresponds to an active host, but an SSL connection cannot be successfully established.
                 Based on this reasoning, we can reliably determine whether the user is within the campus network.
                 */
                switch error.code {
                case .timedOut: fallthrough // the IP address is not in the local network
                case .cannotConnectToHost: fallthrough // the IP address is within the local network, but the server rejects the connection
                case .secureConnectionFailed: fallthrough // the IP address is within the local network, but the server rejects the connection
                case .serverCertificateUntrusted: fallthrough // the server accepts the HTTPS connection, but doesn't have a valid certificate of fduhole.com
                case .serverCertificateNotYetValid:
                    outsideCampus = true
                default:
                    throw error
                }
            }
        }
        
        // use proxy
        
        let proxiedRequest = createProxiedRequest(request: request)
        let (data, response) = try await FudanKit.Authenticator.neo.authenticateRequest(request: proxiedRequest, loginURL: URL(string: "https://webvpn.fudan.edu.cn/login?cas_login=true")!)
        
        // check if webvpn returns the correct data format
        do {
            try validateResponse(response)
            return (data, response)
        } catch is WebVPNDisconnectedError {
            return try await FudanKit.Authenticator.neo.authenticateRequest(request: proxiedRequest, loginURL: URL(string: "https://webvpn.fudan.edu.cn/login?cas_login=true")!, relogin: true)
        }
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
        
        var component = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if request.httpMethod == "PUT",
           let path = component?.path {
            component?.path = path + "/_webvpn"
        }
        let modifiedURL = component?.url ?? url
        
        let proxiedURL = createProxiedURL(url: modifiedURL)

        var proxiedRequest = URLRequest(url: proxiedURL)
        proxiedRequest.allHTTPHeaderFields = request.allHTTPHeaderFields
        proxiedRequest.httpMethod = request.httpMethod == "PUT" ? "PATCH" : request.httpMethod
        proxiedRequest.httpBody = request.httpBody
        return proxiedRequest
    }
}

struct WebVPNError: Error {
    let url: URL?
}

extension WebVPNError: LocalizedError {
    public var errorDescription: String? {
        String(localized: "VPN Error", bundle: .module)
    }
}

public struct WebVPNDisconnectedError: Error, LocalizedError {
    public var errorDescription: String? {
        return "WebVPN disconnected"
    }
}

public class ProxySettings: ObservableObject {
    public static let shared = ProxySettings()
    
    @AppStorage("enable-webvpn") public var enableProxy = true
}
