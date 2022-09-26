import Foundation

let FDUHOLE_AUTH_URL = "https://auth.fduhole.com/api"
let FDUHOLE_BASE_URL = "https://api.fduhole.com"

/// Store the network APIs of DanXI services.
class DXNetworks {
    /// Shared instance of this class.
    static var shared = DXNetworks()
    private let defaults = UserDefaults(suiteName: "group.io.github.kavinzhao.fdutools")
    
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
    
    // MARK: General Methods
    
    init() {
        if let tokenData = defaults?.data(forKey: "user-credential") {
            self.token = try? JSONDecoder().decode(Token.self, from: tokenData)
        }
    }
    
    // use generic type to decode server response
    func requestObj<T: Decodable>(url: URL, data: Data? = nil, method: String? = nil) async throws -> T {
        let data = try await networkRequest(url: url, data: data, method: method)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.invalidResponse
        }
    }
    
    /// Network request primitive, add necessary HTTP headers and authentication infomation.
    /// - Parameters:
    ///   - url: URL to query.
    ///   - data: data to upload.
    ///   - method: HTTP method, default is `GET` or `POST`, depending on whether `data` is `nil`.
    ///   - retry: internal parameter, used to prevent infinite recursion when refreshing token is needed.
    /// - Returns: Server response data.
    func networkRequest(url: URL, data: Data? = nil, method: String? = nil, retry: Bool = false) async throws -> Data {
        struct ServerMessage: Codable {
            let message: String
        }
        
        guard let token = self.token else {
            throw NetworkError.notInitialized
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token.access)", forHTTPHeaderField: "Authorization")
        
        if let payloadData = data {
            request.httpMethod = method ?? "POST"
            request.httpBody = payloadData
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
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
            if error.errorCode == -999 {
                throw NetworkError.ignore // SwiftUI bug cause URLSession to cancel
            } else {
                throw NetworkError.networkError(message: error.localizedDescription)
            }
        }
    }
    
    // MARK: Authentication
    
    /// Login and store user token.
    /// - Parameters:
    ///   - username: username.
    ///   - password: password.
    func login(username: String, password: String) async throws {
        struct LoginBody: Codable {
            let email: String
            let password: String
        }
        
        let loginBody = LoginBody(email: username, password: password)
        let postData = try JSONEncoder().encode(loginBody)
        
        var request = URLRequest(url: URL(string: FDUHOLE_AUTH_URL + "/login")!)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200..<300:
            let responseToken = try JSONDecoder().decode(Token.self, from: data)
            defaults?.setValue(data, forKey: "user-credential")
            self.token = responseToken
            
            if apnsToken != nil {
                Task.init {
                    await DXNetworks.shared.uploadAPNSKey()
                }
            }
        case 400..<500:
            throw NetworkError.unauthorized
        default:
            throw NetworkError.serverError(message: "")
        }
        
    }
    
    func logout() {
        defaults?.removeObject(forKey: "user-credential")
        token = nil
    }
    
    
    /// Request a new token when current token is expired.
    func refreshToken() async throws {
        guard let token = self.token else {
            throw NetworkError.forbidden
        }
        
        do {
            var request = URLRequest(url: URL(string: FDUHOLE_AUTH_URL + "/refresh")!)
            request.setValue("Bearer \(token.refresh)", forHTTPHeaderField: "Authorization")
            request.httpMethod = "POST"
            let (data, _) = try await URLSession.shared.data(for: request)
            let responseToken = try JSONDecoder().decode(Token.self, from: data)
            defaults?.setValue(data, forKey: "user-credential")
            self.token = responseToken
        } catch {
            throw NetworkError.unauthorized
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
