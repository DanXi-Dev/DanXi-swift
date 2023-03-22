import Foundation

// MARK: Auto Refresh

func DXAutoRefresh(_ urlRequest: URLRequest) async throws -> Data {
    var request = urlRequest
    
    do {
        guard let token = DXModel.shared.token else {
            throw DanXiError.tokenNotFound
        }
        request.setValue("Bearer \(token.access)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await sendRequest(request)
        return data
    } catch HTTPError.unauthorized {
        try await DXModel.shared.refreshToken()
        guard let token = DXModel.shared.token else {
            throw DanXiError.tokenNotFound
        }
        request.setValue("Bearer \(token.access)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await sendRequest(request)
        return data
    }
}

// MARK: Intergration

func DXRequest(_ url: URL, method: String? = nil) async throws {
    let request = prepareRequest(url, method: method)
    _ = try await DXAutoRefresh(request)
}

func DXRequest<S: Encodable>(_ url: URL, payload: S, method: String? = nil) async throws {
    let request = try prepareJSONRequest(url, payload: payload, method: method)
    _ = try await DXAutoRefresh(request)
}

func DXResponse<T: Decodable>(_ url: URL, method: String? = nil) async throws -> T {
    let request = prepareRequest(url, method: method)
    let data = try await DXAutoRefresh(request)
    return try processJSONData(data)
}

func DXResponse<T: Decodable, S: Encodable>(_ url: URL, payload: S, method: String? = nil) async throws -> T {
    let request = try prepareJSONRequest(url, payload: payload, method: method)
    let data = try await DXAutoRefresh(request)
    return try processJSONData(data)
}

// MARK: Error

enum DanXiError: LocalizedError {
    case tokenExpired
    case tokenNotFound
    case banned
    case loginFailed
    case registerFailed(message: String)
    case holeNotExist(holeId: Int)
    case floorNotExist(floorId: Int)
    
    public var errorDescription: String? {
        switch self {
        case .tokenExpired:
            return NSLocalizedString("Token expired, login again", comment: "")
        case .tokenNotFound:
            return NSLocalizedString("Token not initialized, contact developer for help", comment: "")
        case .banned:
            return NSLocalizedString("Banned by admin", comment: "")
        case .loginFailed:
            return NSLocalizedString("Incorrect username or password", comment: "")
        case .registerFailed(let message):
            return String(format: NSLocalizedString("Register failed: %@", comment: ""), message)
        
        case .holeNotExist(let holeId):
            return String(format: NSLocalizedString("Treehole #%@ not exist", comment: ""), String(holeId))
        case .floorNotExist(let floorId):
            return String(format: NSLocalizedString("Floor ##%@ not exist", comment: ""), String(floorId))
        }
    }
    
}
