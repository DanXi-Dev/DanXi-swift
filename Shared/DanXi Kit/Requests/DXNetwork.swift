import Foundation

// MARK: URLs

let FDUHOLE_AUTH_URL = "https://auth.fduhole.com/api"
let FDUHOLE_BASE_URL = "https://www.fduhole.com/api"
let DANKE_BASE_URL = "https://danke.fduhole.com/api"

// MARK: Auto Refresh

func autoRefresh(_ urlRequest: URLRequest) async throws -> Data {
    var request = urlRequest
    var refreshed = false
    
    while true {
        do {
            guard let token = DXModel.shared.token else {
                throw DXError.tokenNotFound
            }
            request.setValue("Bearer \(token.access)", forHTTPHeaderField: "Authorization")
            return try await sendRequest(request).0 // return data only
        } catch let error as HTTPError {
            if error.code == 401 && !refreshed {
                try await DXModel.shared.refreshToken()
                refreshed = true
            } else {
                throw error
            }
        }
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
