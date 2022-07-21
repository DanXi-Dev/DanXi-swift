import Foundation
import Alamofire

public enum TreeHoleError: LocalizedError {
    case unauthorized
    case notInitialized
    case serverReturnedError(message: String)
    case invalidResponse
    case invalidFormat(reason: String)
}

extension TreeHoleError {
    public var errorDescription: String? {
        switch self {
        case let .serverReturnedError(message):
            return "The server responded with an error: \(message)"
        case .unauthorized:
            return "Unauthorized"
        case .notInitialized:
            return "Repository not initialized"
        case .invalidResponse:
            return "The server returned an invalid response"
        case let .invalidFormat(reason):
            return "The server returned an malformed response: \(reason)"
        }
    }
}

func THlogin(username: String, password: String) async -> String? {
    struct JWToken: Hashable, Codable {
        var access, refresh: String
    }
    
    struct ServerResponse: Hashable, Codable {
        var message, token: String?
    }
    
    
    let response = await AF.request(FDUHOLE_AUTH_URL + "/login",
                                    method: .post,
                                    parameters: ["email": username, "password": password],
                                    encoder: JSONParameterEncoder.default)
        .serializingString().response
    
    guard let data = response.data else {
        return nil
    }
    
    do {
        if (response.response?.statusCode ?? 999 >= 400) {
            _ = try JSONDecoder().decode(ServerResponse.self, from: data)
            return nil
        }
        
        let decodedJWT = try JSONDecoder().decode(JWToken.self, from: data)
        return decodedJWT.access
    } catch {
        return nil
    }
}

func THloadDivisions(token: String) async throws -> [THDivision] {
    let components = URLComponents(string: FDUHOLE_BASE_URL + "/divisions")!
    var request = URLRequest(url: components.url!)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let decodedResponse = try JSONDecoder().decode([THDivision].self, from: data)
    return decodedResponse
}

func THloadHoles(token: String, startTime: String? = nil, divisionId: Int?) async throws -> [THHole] {
    var components = URLComponents(string: FDUHOLE_BASE_URL + "/holes")!
    components.queryItems = [
        URLQueryItem(name: "start_time", value: startTime),
        URLQueryItem(name: "division_id", value: String(divisionId ?? 1))
    ]
    components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
    var request = URLRequest(url: components.url!)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let decodedResponse = try JSONDecoder().decode([THHole].self, from: data)
    return decodedResponse
}


func THloadFloors(token: String, holeId: Int, startFloor: Int, length: Int = 10) async throws -> [THFloor] {
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
