import Foundation

// FDU Hole API

extension NetworkRequests {
    
    // MARK: generic info
    
    func loadUserInfo() async throws -> THUser {
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/users")!
        let data = try await networkRequest(url: components.url!)
        let decodedResponse = try JSONDecoder().decode(THUser.self, from: data)
        return decodedResponse
    }
    
    func loadDivisions() async throws -> [THDivision] {
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/divisions")!
        let data = try await networkRequest(url: components.url!)
        let decodedResponse = try JSONDecoder().decode([THDivision].self, from: data)
        return decodedResponse
    }
    
    // MARK: tags
    
    func loadTags() async throws -> [THTag] {
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/tags")!
        let data = try await networkRequest(url: components.url!)
        let decodedResponse = try JSONDecoder().decode([THTag].self, from: data)
        return decodedResponse
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
    
    // MARK: holes
    
    func loadHoles(startTime: String? = nil, divisionId: Int?) async throws -> [THHole] {
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/holes")!
        components.queryItems = [URLQueryItem(name: "division_id", value: String(divisionId ?? 1))]
        if let time = startTime {
            components.queryItems?.append(URLQueryItem(name: "start_time", value: time))
        }
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        let data = try await networkRequest(url: components.url!)
        let decodedResponse = try JSONDecoder().decode([THHole].self, from: data)
        return decodedResponse
    }
    
    func loadHoleById(holeId: Int) async throws -> THHole {
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/holes/\(holeId)")!
        let data = try await networkRequest(url: components.url!)
        let decodedResponse = try JSONDecoder().decode(THHole.self, from: data)
        return decodedResponse
    }
    
    func updateViews(holeId: Int) async throws {
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/holes/\(holeId)")!
        _ = try await networkRequest(url: components.url!, method: "PATCH")
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
    
    // MARK: floor
    
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
    
    func loadFloorById(floorId: Int) async throws -> THFloor {
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/floors/\(floorId)")!
        let data = try await networkRequest(url: components.url!)
        let decodedResponse = try JSONDecoder().decode(THFloor.self, from: data)
        return decodedResponse
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
}
