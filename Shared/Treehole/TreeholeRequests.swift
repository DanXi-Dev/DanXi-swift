import Foundation

let FDUHOLE_AUTH_URL = "https://auth.fduhole.com/api"
let FDUHOLE_BASE_URL = "https://api.fduhole.com"

public enum TreeholeError: LocalizedError {
    case unauthorized
    case notInitialized
    case networkError
    case serverError
    case serverReturnedError(message: String)
    case invalidResponse
    case invalidFormat(reason: String)
}

var networks = TreeholeNetworks()

struct TreeholeNetworks {
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
    
    private func networkRequest(url: URL, data: Data? = nil, method: String? = nil) async throws -> Data {
        guard let token = self.token else {
            throw TreeholeError.notInitialized
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
            throw TreeholeError.unauthorized // TODO: if 401, refresh token
        default:
            throw TreeholeError.serverError
        }
        
    }
    
    // MARK: API
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
                throw TreeholeError.unauthorized
            default:
                throw TreeholeError.serverError
            }
        } catch {
            throw TreeholeError.networkError
        }
    }
    
    mutating func logout() {
        defaults?.removeObject(forKey: "user-credential")
        token = nil
    }
    
    func loadDivisions() async throws -> [THDivision] {
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/divisions")!
        let data = try await networkRequest(url: components.url!)
        let decodedResponse = try JSONDecoder().decode([THDivision].self, from: data)
        return decodedResponse
    }
    
    func loadHoles(startTime: String? = nil, divisionId: Int?) async throws -> [THHole] {
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/holes")!
        components.queryItems = [URLQueryItem(name: "division_id", value: String(divisionId ?? 1))]
        if let time = startTime {
            components.queryItems?.append(URLQueryItem(name: "start_time", value: time))
        }
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        let data = try await networkRequest(url: components.url!)
        do {
            let decodedResponse = try JSONDecoder().decode([THHole].self, from: data)
            return decodedResponse
        } catch {
            print(error)
            throw TreeholeError.invalidResponse
        }
        
    }
    
    func loadHoleById(holeId: Int) async throws -> THHole {
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/holes/\(holeId)")!
        let data = try await networkRequest(url: components.url!)
        let decodedResponse = try JSONDecoder().decode(THHole.self, from: data)
        return decodedResponse
    }
    
    func loadFloors(holeId: Int, startFloor: Int, length: Int = 10) async throws -> [THFloor] {
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/floors")!
        components.queryItems = [
            URLQueryItem(name: "hole_id", value: String(holeId)),
            URLQueryItem(name: "length", value: String(length)),
            URLQueryItem(name: "start_floor", value: String(startFloor))
        ]
        let data = try await networkRequest(url: components.url!)
        let decodedResponse = try JSONDecoder().decode([THFloor].self, from: data)
        return decodedResponse
    }
    
    func loadTags() async throws -> [THTag] {
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/tags")!
        let data = try await networkRequest(url: components.url!)
        let decodedResponse = try JSONDecoder().decode([THTag].self, from: data)
        return decodedResponse
    }
    
    func loadUserInfo() async throws -> THUser {
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/users")!
        let data = try await networkRequest(url: components.url!)
        let decodedResponse = try JSONDecoder().decode(THUser.self, from: data)
        return decodedResponse
    }
    
    func newPost(content: String, divisionId: Int, tags: [THTag]) async throws {
        struct Tag: Codable {
            let name: String
        }
        
        struct Post: Codable {
            let content: String
            let division_id: Int
            var tags: [Tag]
        }
        
        var payload = Post(content: content, division_id: divisionId, tags: [])
        for tag in tags {
            payload.tags.append(Tag(name: tag.name))
        }
        let payloadData = try JSONEncoder().encode(payload)
        
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/holes")!
        _ = try await networkRequest(url: components.url!, data: payloadData)
    }
    
    func like(floorId: Int, like: Bool) async throws -> THFloor {
        struct LikeConfig: Codable {
            let like: String
        }
        
        let payload = LikeConfig(like: like ? "add" : "cancel")
        let payloadData = try JSONEncoder().encode(payload)
        
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/floors/\(floorId)")!
        let data = try await networkRequest(url: components.url!, data: payloadData, method: "PUT")
        
        let floor = try JSONDecoder().decode(THFloor.self, from: data)
        return floor
    }
    
    func deleteFloor(floorId: Int) async throws -> THFloor {
        struct DeleteConfig: Codable {
            let delete_reason: String
        }
                
        let payload = DeleteConfig(delete_reason: "")
        let payloadData = try JSONEncoder().encode(payload)
        
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/floors/\(floorId)")!
        let data = try await networkRequest(url: components.url!, data: payloadData, method: "DELETE")
        
        let floor = try JSONDecoder().decode(THFloor.self, from: data)
        return floor
    }
    
    func searchKeyword(keyword: String, startFloor: Int = 0) async throws -> [THFloor] {
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/floors")!
        components.queryItems = [
            URLQueryItem(name: "s", value: keyword),
            URLQueryItem(name: "length", value: "10"),
            URLQueryItem(name: "start_floor", value: String(startFloor))
        ]
        let data = try await networkRequest(url: components.url!)

        let floors = try JSONDecoder().decode([THFloor].self, from: data)
        return floors
    }
    
    func searchTag(tagName: String, divisionId: Int?, startTime: String? = nil) async throws -> [THHole] {
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/holes")!
        components.queryItems = [URLQueryItem(name: "tag", value: tagName)]
        if let time = startTime {
            components.queryItems?.append(URLQueryItem(name: "start_time", value: time))
        }
        if let divisionId = divisionId {
            components.queryItems?.append(URLQueryItem(name: "division_id", value: String(divisionId)))
        }
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        let data = try await networkRequest(url: components.url!)
        let decodedResponse = try JSONDecoder().decode([THHole].self, from: data)
        return decodedResponse
    }
    
    func reply(content: String, holdId: Int) async throws -> THFloor {
        struct ReplyObject: Codable {
            let content: String
            var hole_id: Int
        }
        
        struct ServerResponse: Decodable {
            let message: String
            var data: THFloor
        }

        let payload = ReplyObject(content: content, hole_id: holdId)
        let payloadData = try JSONEncoder().encode(payload)

        let components = URLComponents(string: FDUHOLE_BASE_URL + "/floors")!
        let data = try await networkRequest(url: components.url!, data: payloadData)

        let responseData = try JSONDecoder().decode(ServerResponse.self, from: data)
        return responseData.data
    }
    
    func editReply(content: String, floorId: Int) async throws -> THFloor {
        struct EditConfig: Codable {
            let content: String
        }
        
        let payload = EditConfig(content: content)
        let payloadData = try JSONEncoder().encode(payload)
        
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/floors/\(floorId)")!
        let data = try await networkRequest(url: components.url!, data: payloadData, method: "PUT")
        
        let floor = try JSONDecoder().decode(THFloor.self, from: data)
        return floor
    }
    
    func loadFavorites() async throws -> [THHole] {
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/user/favorites")!
        let data = try await networkRequest(url: components.url!)
        let holes = try JSONDecoder().decode([THHole].self, from: data)
        return holes
    }
    
    func toggleFavorites(holeId: Int, add: Bool) async throws -> [Int] {
        struct FavoriteConfig: Codable {
            let hole_id: Int
        }
        
        struct ServerResponse: Codable {
            let message: String
            var data: [Int]
        }
        
        let payload = FavoriteConfig(hole_id: holeId)
        let payloadData = try JSONEncoder().encode(payload)
        
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/user/favorites")!
        let data = try await networkRequest(url: components.url!, data: payloadData, method: add ? "POST" : "DELETE")
        let decodedData = try JSONDecoder().decode(ServerResponse.self, from: data)
        return decodedData.data
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
