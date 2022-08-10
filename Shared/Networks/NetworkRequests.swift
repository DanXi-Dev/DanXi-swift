import Foundation

let FDUHOLE_AUTH_URL = "https://auth.fduhole.com/api"
let FDUHOLE_BASE_URL = "https://api.fduhole.com"



var networks = NetworkRequests()

struct NetworkRequests {
    private let defaults = UserDefaults(suiteName: "group.io.github.kavinzhao.fdutools")
    var token: String?
    
    var isInitialized: Bool {
        token != nil
    }
    
    init() {
        if let token = defaults?.string(forKey: "user-credential") {
            self.token = token
        }
    }
    
    func networkRequest(url: URL, data: Data? = nil, method: String? = nil) async throws -> Data {
        guard let token = self.token else {
            throw NetworkError.notInitialized
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let payloadData = data {
            request.httpMethod = method ?? "POST"
            request.httpBody = payloadData
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        switch httpResponse.statusCode {
        case 200..<300:
            return data
        case 400..<500:
            throw NetworkError.unauthorized // TODO: if 401, refresh token
        default:
            throw NetworkError.serverError(message: "")
        }
        
    }
    
    // MARK: auth
    mutating func login(username: String, password: String) async throws {
        struct LoginBody: Codable {
            let email: String
            let password: String
        }
        
        struct Token: Codable {
            let access: String
            let refresh: String
        }
        
        do {
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
                defaults?.setValue(responseToken.access, forKey: "user-credential")
                self.token = responseToken.access
                
                if apnsToken != nil {
                    Task.init {
                        await networks.uploadAPNSKey()
                    }
                }
            case 400..<500:
                throw NetworkError.unauthorized
            default:
                throw NetworkError.serverError(message: "")
            }
        } catch {
            throw NetworkError.networkError
        }
    }
    
    mutating func logout() {
        defaults?.removeObject(forKey: "user-credential")
        token = nil
    }
    
    // MARK: APNS
    var apnsToken: APNSToken? = nil
    
    mutating func cacheOrUploadAPNSKey(token: String, deviceId: String) {
        apnsToken = APNSToken(service: "apns", device_id: deviceId, token: token)
        if isInitialized {
            Task.init {
                await networks.uploadAPNSKey()
            }
        }
    }
    
    mutating func uploadAPNSKey() async {
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
