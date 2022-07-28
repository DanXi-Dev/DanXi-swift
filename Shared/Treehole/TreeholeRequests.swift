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
    
    init() {
        if let token = defaults?.string(forKey: "user-credential") {
            self.token = token
        }
    }
    
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
        guard let token = self.token else {
            throw TreeholeError.notInitialized
        }
        
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/divisions")!
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decodedResponse = try JSONDecoder().decode([THDivision].self, from: data)
        return decodedResponse
    }
    
    func loadHoles(startTime: String? = nil, divisionId: Int?) async throws -> [THHole] {
        guard let token = self.token else {
            throw TreeholeError.notInitialized
        }
        
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/holes")!
        components.queryItems = [URLQueryItem(name: "division_id", value: String(divisionId ?? 1))]
        if let time = startTime {
            components.queryItems?.append(URLQueryItem(name: "start_time", value: time))
        }
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decodedResponse = try JSONDecoder().decode([THHole].self, from: data)
        return decodedResponse
    }
    
    func loadFloors(holeId: Int, startFloor: Int, length: Int = 10) async throws -> [THFloor] {
        guard let token = self.token else {
            throw TreeholeError.notInitialized
        }
        
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/floors")!
        components.queryItems = [
            URLQueryItem(name: "hole_id", value: String(holeId)),
            URLQueryItem(name: "length", value: String(length)),
            URLQueryItem(name: "start_floor", value: String(startFloor))
        ]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decodedResponse = try JSONDecoder().decode([THFloor].self, from: data)
        return decodedResponse
    }
    
    func loadTags() async throws -> [THTag] {
        guard let token = self.token else {
            throw TreeholeError.notInitialized
        }
        
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/tags")!
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decodedResponse = try JSONDecoder().decode([THTag].self, from: data)
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
        
        guard let token = self.token else {
            throw TreeholeError.notInitialized
        }
        
        var payload = Post(content: content, division_id: divisionId, tags: [])
        for tag in tags {
            payload.tags.append(Tag(name: tag.name))
        }
        let payloadData = try JSONEncoder().encode(payload)
        
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/holes")!
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.httpBody = payloadData
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        guard httpResponse.statusCode <= 299 else {
            throw TreeholeError.serverReturnedError(message: String(httpResponse.statusCode))
        }
    }
    
    func like(floorId: Int, like: Bool) async throws -> THFloor {
        struct LikeConfig: Codable {
            let like: String
        }
        
        guard let token = self.token else {
            throw TreeholeError.notInitialized
        }
        
        let payload = LikeConfig(like: like ? "add" : "cancel")
        let payloadData = try JSONEncoder().encode(payload)
        
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/floors/\(floorId)")!
        var request = URLRequest(url: components.url!)
        request.httpMethod = "PUT"
        request.httpBody = payloadData
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        guard httpResponse.statusCode <= 299 else {
            throw TreeholeError.serverReturnedError(message: String(httpResponse.statusCode))
        }
        
        let floor = try JSONDecoder().decode(THFloor.self, from: data)
        return floor
    }
    
    func deleteFloor(floorId: Int) async throws -> THFloor {
        struct DeleteConfig: Codable {
            let delete_reason: String
        }
        
        guard let token = self.token else {
            throw TreeholeError.notInitialized
        }
        
        let payload = DeleteConfig(delete_reason: "")
        let payloadData = try JSONEncoder().encode(payload)
        
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/floors/\(floorId)")!
        var request = URLRequest(url: components.url!)
        request.httpMethod = "DELETE"
        request.httpBody = payloadData
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        guard httpResponse.statusCode <= 299 else {
            throw TreeholeError.serverReturnedError(message: String(httpResponse.statusCode))
        }
        
        let floor = try JSONDecoder().decode(THFloor.self, from: data)
        return floor
    }
    
    func uploadAPNSKey(apnsToken: String, deviceId: String) {
        // TODO: finish this
    }
}
