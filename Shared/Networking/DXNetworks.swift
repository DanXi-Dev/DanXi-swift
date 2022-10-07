import Foundation

let FDUHOLE_AUTH_URL = "https://auth.fduhole.com/api"
let FDUHOLE_BASE_URL = "https://www.fduhole.com/api"

/// Store the network APIs of DanXI services.
class DXNetworks {
    /// Shared instance of this class.
    static var shared = DXNetworks()
    let defaults = UserDefaults(suiteName: "group.io.github.kavinzhao.fdutools")
    
    // MARK: Stored Properties
    
    struct Token: Codable {
        let access: String
        let refresh: String
    }
    /// The user token for protected APIs
    var token: Token?
    
    var isInitialized: Bool {
        token != nil
    }
    
    init() {
        if let tokenData = defaults?.data(forKey: "user-credential") {
            self.token = try? JSONDecoder().decode(Token.self, from: tokenData)
        }
    }
    
    // MARK: General Methods
    
    /// Request for a server response.
    /// - Parameters:
    ///   - url: URL to query.
    ///   - method: HTTP method, default is `GET`.
    /// - Returns: Server response decoded object.
    func requestObj<T: Decodable>(url: URL,
                                  method: String? = nil) async throws -> T {
        let responseData = try await networkRequest(url: url,
                                                    method: method)
        do {
            return try JSONDecoder().decode(T.self, from: responseData)
        } catch {
            throw NetworkError.invalidResponse
        }
    }
    
    /// Request for a server response.
    /// - Parameters:
    ///   - url: URL to query.
    ///   - payload: Payload object, should conform to `Encodable`.
    ///   - method: HTTP method, default is `GET` or `POST`, depending on whether `payload` is `nil`.
    ///   - authorize: Whether to add authorization token in request, default `true`.
    /// - Returns: Server response decoded object.
    func requestObj<T: Decodable, S: Encodable>(url: URL,
                                                payload: S,
                                                method: String? = nil,
                                                authorize: Bool = true) async throws -> T {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let payloadData = try encoder.encode(payload)
        
        let responseData = try await networkRequest(url: url,
                                                    data: payloadData,
                                                    method: method,
                                                    authorize: authorize)
        do {
            return try JSONDecoder().decode(T.self, from: responseData)
        } catch {
            throw NetworkError.invalidResponse
        }
    }
    
    /// Send request to server, ignore response.
    /// - Parameters:
    ///   - url: URL to query.
    ///   - payload: Payload object, should conform to `Encodable`.
    ///   - method: HTTP method, default is `GET` or `POST`, depending on whether `payload` is `nil`.
    func sendRequest<S: Encodable>(url: URL,
                                   payload: S,
                                   method: String? = nil) async throws {
        var payloadData: Data?
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        payloadData = try encoder.encode(payload)
        
        _ = try await networkRequest(url: url,
                                     data: payloadData,
                                     method: method)
    }
    
    /// Send request to server, ignore response.
    /// - Parameters:
    ///   - url: URL to query.
    ///   - method: HTTP method, default is `GET`.
    func sendRequest(url: URL, method: String? = nil) async throws {
        _ = try await networkRequest(url: url, method: method)
    }
    
    /// Network request primitive, add necessary HTTP headers and authentication infomation.
    /// - Parameters:
    ///   - url: URL to query.
    ///   - data: data to upload.
    ///   - method: HTTP method, default is `GET` or `POST`, depending on whether `data` is `nil`.
    ///   - authorize: Whether to add authorization token in request, default `true`.
    ///   - retry: internal parameter, used to prevent infinite recursion when refreshing token is needed.
    /// - Returns: Server response data.
    func networkRequest(url: URL,
                        data: Data? = nil,
                        method: String? = nil,
                        authorize: Bool = true,
                        retry: Bool = false) async throws -> Data {
        struct ServerMessage: Codable {
            let message: String
        }
        
        var request = URLRequest(url: url)
        
        if authorize {
            guard let token = self.token else {
                throw NetworkError.notInitialized
            }
            request.setValue("Bearer \(token.access)", forHTTPHeaderField: "Authorization")
        }
        
        if let payloadData = data {
            request.httpMethod = method ?? "POST"
            request.httpBody = payloadData
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        } else {
            request.httpMethod = method ?? "GET"
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200..<300:
                    return data
                case 401:
                    if retry {
                        throw NetworkError.unauthorized
                    }
                    
                    // refresh token and retry
                    try await refreshToken()
                    return try await networkRequest(url: url, data: data, method: method, retry: true)
                case 403:
                    throw NetworkError.forbidden
                case 404:
                    throw NetworkError.notFound
                case 400..<500:
                    let serverResponse = try? JSONDecoder().decode(ServerMessage.self, from: data)
                    throw NetworkError.invalidRequest(message: serverResponse?.message ?? "")
                case 500..<600:
                    let serverResponse = try? JSONDecoder().decode(ServerMessage.self, from: data)
                    throw NetworkError.serverError(message: serverResponse?.message ?? "")
                default:
                    throw NetworkError.invalidResponse
                }
            } else {
                throw NetworkError.invalidResponse
            }
            
        } catch let error as URLError {
            throw NetworkError.networkError(message: error.localizedDescription)
        }
    }
    
    
    /// Store token to `UserDefaults`.
    /// - Parameter token: JWT Token. If `nil`, remove stored token.
    func storeToken(_ token: Token?) {
        if let token = token {
            let data = try! JSONEncoder().encode(token)
            defaults?.setValue(data, forKey: "user-credential")
            self.token = token
        } else {
            defaults?.removeObject(forKey: "user-credential")
            self.token = nil
        }
    }
    
    
    // MARK: APNS
    var apnsToken: APNSToken? = nil
    
    func cacheOrUploadAPNSKey(token: String, deviceId: String) {
        apnsToken = APNSToken(service: "apns", device_id: deviceId, token: token)
        if isInitialized {
            Task.init {
                await DXNetworks.shared.uploadAPNSKey()
            }
        }
    }
    
    func uploadAPNSKey() async {
        print("Uploading APNS Key \(String(describing: apnsToken?.token))")
        do {
            let payloadData = try JSONEncoder().encode(apnsToken)
            let components = URLComponents(string: FDUHOLE_BASE_URL + "/users/push-tokens")!
            _ = try await networkRequest(url: components.url!, data: payloadData, method: "PUT")
            apnsToken = nil
        } catch {
            print("APNS Upload Failed \(error)")
        }
    }
}

struct APNSToken: Codable {
    let service: String
    let device_id: String
    let token: String
}
