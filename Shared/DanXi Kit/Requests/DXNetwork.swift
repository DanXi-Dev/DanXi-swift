import Foundation
import Queue

// MARK: URLs

var FDUHOLE_AUTH_URL = UserDefaults.standard.string(forKey: "fduhole_auth_url") ?? "https://auth.fduhole.com/api"
var FDUHOLE_BASE_URL = UserDefaults.standard.string(forKey: "fduhole_base_url") ?? "https://www.fduhole.com/api"
var DANKE_BASE_URL = UserDefaults.standard.string(forKey: "danke_base_url") ?? "https://danke.fduhole.com/api"


// MARK: Auto Refresh

let autoRefreshQueue = AsyncQueue(attributes: [.concurrent])

func autoRefresh(_ urlRequest: URLRequest, alreadyRefreshed: Bool = false) async throws -> Data {
    guard let token = await DXModel.shared.token else {
        throw DXError.tokenNotFound
    }
    var request = urlRequest
    request.setValue("Bearer \(token.access)", forHTTPHeaderField: "Authorization")
    let newRequest = request
    
    // First try
    let task = autoRefreshQueue.addOperation {
        return try await sendRequest(newRequest).0 // return data only
    }
    do {
        return try await task.value
    } catch let error as HTTPError {
        if error.code == 401 && !alreadyRefreshed {
            // Refresh Token
            let refreshTask = autoRefreshQueue.addBarrierOperation {
                guard let newToken = await DXModel.shared.token else {
                    throw DXError.tokenNotFound
                }
                if newToken.access == token.access {
                    // Token has not been refreshed by other processes, commence token refresh on this barrier operation
                    try await DXModel.shared.refreshToken()
                }
            }
            try await refreshTask.value
            // and retry
            return try await autoRefresh(urlRequest, alreadyRefreshed: true)
        }
        throw error
    }
}

// MARK: Convenience Methods

func DXRequest(_ url: URL, method: String? = nil) async throws {
    let request = prepareRequest(url, method: method)
    _ = try await autoRefresh(request)
}

func DXRequest<S: Encodable>(_ url: URL, payload: S, method: String? = nil) async throws {
    let request = try prepareJSONRequest(url, payload: payload, method: method)
    _ = try await autoRefresh(request)
}

func DXResponse<T: Decodable>(_ url: URL, method: String? = nil) async throws -> T {
    let request = prepareRequest(url, method: method)
    let data = try await autoRefresh(request)
    return try processJSONData(data)
}

func DXResponse<T: Decodable, S: Encodable>(_ url: URL, payload: S, method: String? = nil) async throws -> T {
    let request = try prepareJSONRequest(url, payload: payload, method: method)
    let data = try await autoRefresh(request)
    return try processJSONData(data)
}
