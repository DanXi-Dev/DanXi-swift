import Foundation

// FDU Hole API

extension DXNetworks {
    
    // MARK: generic info
    
    func loadUserInfo() async throws -> THUser {
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/users")!
        return try await requestObj(url: components.url!)
    }
    
    // MARK: Division
    
    
    /// List all divisions.
    /// - Returns: A list of `THDivision`
    func loadDivisions() async throws -> [THDivision] {
        let url = URL(string: FDUHOLE_BASE_URL + "/divisions")!
        return try await requestObj(url: url)
    }
    
    
    /// Get division by ID.
    /// - Parameter id: Division ID.
    /// - Returns: The matching `THDivision`.
    func getDivision(id: Int) async throws -> THDivision {
        let url = URL(string: FDUHOLE_BASE_URL + "/divisions/\(id)")!
        return try await requestObj(url: url)
    }
    
    
    // MARK: tags
    
    func loadTags() async throws -> [THTag] {
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/tags")!
        return try await requestObj(url: components.url!)
    }
    
    
    // MARK: Hole
    
    
    // TODO: deprecated API
    func loadHoles(startTime: String? = nil, divisionId: Int?) async throws -> [THHole] {
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/holes")!
        components.queryItems = [URLQueryItem(name: "division_id", value: String(divisionId ?? 1))]
        if let time = startTime {
            components.queryItems?.append(URLQueryItem(name: "start_time", value: time))
        }
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        return try await requestObj(url: components.url!)
    }
    
    // TODO: deprecated API
    func createHole(content: String, divisionId: Int, tags: [String]) async throws {
        struct Tag: Codable {
            let name: String
        }
        
        struct Post: Codable {
            let content: String
            let division_id: Int
            var tags: [Tag]
        }
        
        let payload = Post(content: content,
                           division_id: divisionId,
                           tags: tags.map { Tag(name: $0) })
        let payloadData = try JSONEncoder().encode(payload)
        
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/holes")!
        _ = try await networkRequest(url: components.url!, data: payloadData)
    }
    
    
    /// Get hole by ID.
    /// - Parameter holeId: Hole ID.
    /// - Returns: The matching `THHole`.
    func loadHoleById(holeId: Int) async throws -> THHole {
        let url = URL(string: FDUHOLE_BASE_URL + "/holes/\(holeId)")!
        return try await requestObj(url: url)
    }
    
    
    /// Modify hole.
    /// - Parameters:
    ///   - holeId: Hole ID to change.
    ///   - tags: New tags.
    ///   - divisionId: Move hole to new division.
    func modifyHole(holeId: Int, tags: [String], divisionId: Int) async throws {
        struct Tag: Codable {
            let name: String
        }
        
        struct EditConfig: Codable {
            let tags: [Tag]
            let division_id: Int
            // TODO: unhidden: Bool
        }
        
        let payload = EditConfig(tags: tags.map { Tag(name: $0) },
                                 division_id: divisionId)
        let payloadData = try JSONEncoder().encode(payload)
        
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/holes/\(holeId)")!
        _ = try await networkRequest(url: components.url!, data: payloadData, method: "PUT")
    }
    
    
    /// Hide a hole, only visible to admins.
    /// - Parameter holeId: Hole ID.
    func deleteHole(holeId: Int) async throws {
        let url = URL(string: FDUHOLE_BASE_URL + "holes/\(holeId)")!
        _ = try await networkRequest(url: url, method: "DELETE")
    }
    
    
    /// Update hole view count.
    /// - Parameter holeId: Hole ID.
    func updateViews(holeId: Int) async throws {
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/holes/\(holeId)")!
        _ = try await networkRequest(url: components.url!, method: "PATCH")
    }
    
    
    /// List holes by tag.
    /// - Parameters:
    ///   - tagName: Tag name.
    ///   - startTime: update time offset
    /// - Returns: List of `THHole`.
    func listHoleByTag(tagName: String, startTime: String? = nil) async throws -> [THHole] {
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/holes")!
        components.queryItems = [URLQueryItem(name: "tag", value: tagName)]
        if let time = startTime {
            components.queryItems?.append(URLQueryItem(name: "start_time", value: time))// TODO: Deprecated API (offset)
        }
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        return try await requestObj(url: components.url!)
    }
    
    
    // MARK: Floor
    
    func loadFloors(holeId: Int, startFloor: Int, length: Int = 10) async throws -> [THFloor] {
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/floors")!
        components.queryItems = [
            URLQueryItem(name: "hole_id", value: String(holeId)),
            URLQueryItem(name: "length", value: String(length)),
            URLQueryItem(name: "start_floor", value: String(startFloor))
        ]
        return try await requestObj(url: components.url!)
    }
    
    func loadFloorById(floorId: Int) async throws -> THFloor {
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/floors/\(floorId)")!
        return try await requestObj(url: components.url!)
    }
    
    func deleteFloor(floorId: Int, reason: String = "") async throws -> THFloor {
        struct DeleteConfig: Codable {
            let delete_reason: String
        }
        
        let payload = DeleteConfig(delete_reason: reason)
        let payloadData = try JSONEncoder().encode(payload)
        
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/floors/\(floorId)")!
        return try await requestObj(url: components.url!, data: payloadData, method: "DELETE")
    }
    
    func like(floorId: Int, like: Bool) async throws -> THFloor {
        struct LikeConfig: Codable {
            let like: String
        }
        
        let payload = LikeConfig(like: like ? "add" : "cancel")
        let payloadData = try JSONEncoder().encode(payload)
        
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/floors/\(floorId)")!
        return try await requestObj(url: components.url!, data: payloadData, method: "PUT")
    }
    
    func searchKeyword(keyword: String, startFloor: Int = 0) async throws -> [THFloor] {
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/floors")!
        components.queryItems = [
            URLQueryItem(name: "s", value: keyword),
            URLQueryItem(name: "length", value: "10"),
            URLQueryItem(name: "start_floor", value: String(startFloor))
        ]
        return try await requestObj(url: components.url!)
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
        let responseData: ServerResponse = try await requestObj(url: components.url!, data: payloadData)
        return responseData.data
    }
    
    func editReply(content: String, floorId: Int) async throws -> THFloor {
        struct EditConfig: Codable {
            let content: String
        }
        
        let payload = EditConfig(content: content)
        let payloadData = try JSONEncoder().encode(payload)
        
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/floors/\(floorId)")!
        return try await requestObj(url: components.url!, data: payloadData, method: "PUT")
    }
    
    // MARK: management
    


    

    
    // MARK: Report
    
    
    /// List all reports.
    /// - Returns: A list of `THReport`
    func loadReportsList() async throws -> [THReport] {
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/reports")!
        components.queryItems = [ URLQueryItem(name: "category", value: "not_dealed") ]
        return try await requestObj(url: components.url!)
    }
    
    
    /// Add a report
    /// - Parameters:
    ///   - floorId: Floor ID to report.
    ///   - reason: Report reason.
    func report(floorId: Int, reason: String) async throws {
        struct ReportConfig: Codable {
            let floor_id: Int
            let reason: String
        }
        
        let payload = ReportConfig(floor_id: floorId, reason: reason)
        let payloadData = try JSONEncoder().encode(payload)
        
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/reports")!
        _ = try await networkRequest(url: components.url!, data: payloadData, method: "POST")
    }
    
    
    /// Get a report by ID.
    /// - Parameter reportId: Report ID
    /// - Returns: A matching `THReport`.
    func getReportById(reportId: Int) async throws -> THReport {
        let url = URL(string: FDUHOLE_BASE_URL + "/reports/\(reportId)")!
        return try await requestObj(url: url)
    }
    
    
    /// Mark a report as dealt.
    /// - Parameter reportId: Report ID.
    /// - Returns: Dealt `THReport` struct.
    func dealReport(reportId: Int) async throws -> THReport {
        let url = URL(string: FDUHOLE_BASE_URL + "/reports/\(reportId)")!
        return try await requestObj(url: url, method: "DELETE")
    }
    
    
    // MARK: Favorite
    
    func loadFavorites() async throws -> [THHole] {
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/user/favorites")!
        return try await requestObj(url: components.url!)
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
        let response: ServerResponse = try await requestObj(url: components.url!, data: payloadData, method: add ? "POST" : "DELETE")
        return response.data
    }
    
    
    // MARK: Penalty
    
    /// Ban user.
    /// - Parameters:
    ///   - floor: floor to be banned.
    ///   - level: Ban level, range: 1-3.
    func addPenalty(floor: THFloor, level: Int) async throws {
        struct BanConfig: Codable {
            let penalty_level: Int
            let division_id: Int
        }
        
        // get division ID
        let hole = try await loadHoleById(holeId: floor.holeId)
        let divisionId = hole.divisionId
        
        let url = URL(string: FDUHOLE_BASE_URL + "/penalty/\(floor.id)")!
        let payload = BanConfig(penalty_level: level, division_id: divisionId)
        let payloadData = try JSONEncoder().encode(payload)
        _ = try await networkRequest(url: url, data: payloadData)
    }
}
