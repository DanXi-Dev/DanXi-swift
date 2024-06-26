import Foundation
import KeychainAccess
import FudanKit

class Proxy {
    static func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let proxyRequest = createProxiedRequest(request: request)
        return try await FudanKit.Authenticator.shared.authenticateWithResponse(proxyRequest, manualLoginURL: URL(string: "https://webvpn.fudan.edu.cn/login?cas_login=true")!)
    }
    
    static func createProxiedRequest(request: URLRequest) -> URLRequest {
        guard let url = request.url, let host = url.host else {
            return request
        }

        let proxiedURLString: String
        switch host {
        case "www.fduhole.com":
            let path = url.absoluteString.trimmingPrefix("https://www.fduhole.com")
            proxiedURLString = "https://webvpn.fudan.edu.cn/https/77726476706e69737468656265737421e7e056d221347d5871048ce29b5a2e" + path
        case "auth.fduhole.com":
            let path = url.absoluteString.trimmingPrefix("https://auth.fduhole.com")
            proxiedURLString = "https://webvpn.fudan.edu.cn/https/77726476706e69737468656265737421f1e2559469366c45760785a9d6562c38" + path
        case "danke.fduhole.com":
            let path = url.absoluteString.trimmingPrefix("https://danke.fduhole.com")
            proxiedURLString = "https://webvpn.fudan.edu.cn/https/77726476706e69737468656265737421f4f64f97227e6e546b0086a09d1b203a73" + path
        default:
            return request
        }

        guard let proxiedURL = URL(string: proxiedURLString) else {
            return request
        }

        var proxiedRequest = URLRequest(url: proxiedURL)
        proxiedRequest.allHTTPHeaderFields = request.allHTTPHeaderFields
        proxiedRequest.httpMethod = request.httpMethod
        proxiedRequest.httpBody = request.httpBody
        return proxiedRequest
    }
}
