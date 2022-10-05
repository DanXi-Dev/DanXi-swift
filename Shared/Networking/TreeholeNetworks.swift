import Foundation

extension DXNetworks {
    
    // MARK: Division
    
    
    /// List all divisions.
    /// - Returns: A list of `THDivision`
    func loadDivisions() async throws -> [THDivision] {
        return try await requestObj(url: URL(string: FDUHOLE_BASE_URL + "/divisions")!)
    }
    
    
    /// Get division by ID.
    /// - Parameter id: Division ID.
    /// - Returns: The matching `THDivision`.
    func getDivision(id: Int) async throws -> THDivision {
        return try await requestObj(url: URL(string: FDUHOLE_BASE_URL + "/divisions/\(id)")!)
    }
    
    
    // MARK: Hole
    
    
    /// List holes in a division.
    /// - Parameters:
    ///   - startTime: Updated time offset, default is now.
    ///   - divisionId: Division ID.
    /// - Returns: A list of holes.
    func loadHoles(startTime: String? = nil, divisionId: Int) async throws -> [THHole] {
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/divisions/\(divisionId)/holes")!
        if let time = startTime {
            components.queryItems?.append(URLQueryItem(name: "start_time", value: time))
            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        }
        return try await requestObj(url: components.url!)
    }
    
    
    /// Create a hole.
    /// - Parameters:
    ///   - content: First floor content.
    ///   - divisionId: Division to post new hole.
    ///   - tags: Tags of the new hole.
    ///   - specialTag: First floor special tag, admin only.
    func createHole(content: String, divisionId: Int, tags: [String], specialTag: String = "") async throws {
        struct Tag: Codable {
            let name: String
        }
        
        struct Post: Codable {
            let content: String
            let specialTag: String
            var tags: [Tag]
        }
        
        let payload = Post(content: content,
                           specialTag: specialTag,
                           tags: tags.map { Tag(name: $0) })
        try await sendRequest(url: URL(string: FDUHOLE_BASE_URL + "/divisions/\(divisionId)/holes")!,
                                     payload: payload)
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
    ///   - unhidden: Whether to delete
    func modifyHole(holeId: Int,
                    tags: [String],
                    divisionId: Int,
                    unhidden: Bool = true) async throws {
        struct Tag: Codable {
            let name: String
        }
        
        struct EditConfig: Codable {
            let tags: [Tag]
            let divisionId: Int
            let unhidden: Bool
        }
        
        let payload = EditConfig(tags: tags.map { Tag(name: $0) },
                                 divisionId: divisionId,
                                 unhidden: unhidden)
        let payloadData = try JSONEncoder().encode(payload)
        
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/holes/\(holeId)")!
        _ = try await networkRequest(url: components.url!, data: payloadData, method: "PUT")
    }
    
    
    /// Hide a hole, only visible to admins.
    /// - Parameter holeId: Hole ID.
    func deleteHole(holeId: Int) async throws {
        let url = URL(string: FDUHOLE_BASE_URL + "/holes/\(holeId)")!
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
        components.queryItems = [URLQueryItem(name: "tag_name", value: tagName)]
        if let time = startTime {
            components.queryItems?.append(URLQueryItem(name: "offset", value: time))
        }
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        return try await requestObj(url: components.url!)
    }
    
    
    // MARK: Floor
    
    
    /// Get a floor by ID.
    /// - Parameter floorId: Floor ID.
    func loadFloorById(floorId: Int) async throws -> THFloor {
        return try await requestObj(url: URL(string: FDUHOLE_BASE_URL + "/floors/\(floorId)")!)
    }
    
    
    /// Modify a floor.
    /// - Parameters:
    ///   - content: New content.
    ///   - floorId: Floor ID.
    ///   - specialTag: Optional, special tag, admin only.
    /// - Returns: Modified floor.
    func modifyFloor(content: String,
                     floorId: Int,
                     specialTag: String = "") async throws -> THFloor {
        struct EditConfig: Codable {
            let content: String
            let specialTag: String
            // TODO: fold
        }
        
        return try await requestObj(url: URL(string: FDUHOLE_BASE_URL + "/floors/\(floorId)")!,
                                    payload: EditConfig(content: content, specialTag: specialTag),
                                    method: "PUT")
    }
    
    
    /// Delete a floor.
    /// - Parameters:
    ///   - floorId: Floor ID to be deleted.
    ///   - reason: Delete reason, admin only.
    /// - Returns: Deleted floor struct.
    func deleteFloor(floorId: Int, reason: String = "") async throws -> THFloor {
        struct DeleteConfig: Codable {
            let deleteReason: String
        }
        
        return try await requestObj(url: URL(string: FDUHOLE_BASE_URL + "/floors/\(floorId)")!,
                                    payload: DeleteConfig(deleteReason: reason), method: "DELETE")
    }
    
    
    /// Get a floor's history.
    /// - Parameter floorId: Floor ID.
    func loadFloorHistory(floorId: Int) async throws -> [THHistory] {
        return try await requestObj(url: URL(string: FDUHOLE_BASE_URL + "/floors/\(floorId)/history")!)
    }
    
    
    /// Like or unlike a floor.
    /// - Parameters:
    ///   - floorId: Floor ID.
    ///   - like: Set like status.
    /// - Returns: Modified floor.
    func like(floorId: Int, like: Bool) async throws -> THFloor { // TODO: Implement dislike
        let likeConfig = like ? 1 : 0
        return try await requestObj(url: URL(string: FDUHOLE_BASE_URL + "/floors/\(floorId)/like/\(likeConfig)")!,
                                    method: "POST")
    }
    
    
    /// Restore a floor from a history version.
    /// - Parameters:
    ///   - floorId: Floor ID.
    ///   - historyId: History ID.
    ///   - restoreReason: Restore reason.
    /// - Returns: Restored floor.
    func restoreFloor(floorId: Int, historyId: Int, restoreReason: String) async throws -> THFloor {
        struct RestoreConfig: Codable {
            let restoreReason: String
        }
        
        return try await requestObj(url: URL(string: FDUHOLE_BASE_URL + "/floors/\(floorId)/restore/\(historyId)")!,
                                    payload: RestoreConfig(restoreReason: restoreReason))
    }
    
    
    /// List floors from a hole.
    /// - Parameters:
    ///   - holeId: Hole ID.
    ///   - startFloor: Start floor offset.
    /// - Returns: A list of floors.
    func loadFloors(holeId: Int, startFloor: Int) async throws -> [THFloor] {
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/holes/\(holeId)/floors")!
        components.queryItems = [
            URLQueryItem(name: "offset", value: String(startFloor))
            // TODO: order by
            // TODO: sort
        ]
        return try await requestObj(url: components.url!)
    }
    
    
    /// Load all floors within a given hole. (Undocumented API)
    /// - Parameter holeId: Hole ID.
    /// - Returns: A list of floors.
    func loadAllFloors(holeId: Int) async throws -> [THFloor] {
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/holes/\(holeId)/floors")!
        components.queryItems = [
            URLQueryItem(name: "size", value: "0"),
            URLQueryItem(name: "offset", value: "0")
        ]
        return try await requestObj(url: components.url!)
    }
    
    
    /// Create a floor.
    /// - Parameters:
    ///   - content: Floor content.
    ///   - holeId: Hole ID.
    ///   - specialTag: Optional, special tag, admin only.
    /// - Returns: Created floor.
    func createFloor(content: String, holeId: Int, specialTag: String = "") async throws -> THFloor {
        struct ReplyConfig: Codable {
            let content: String
            let specialTag: String
            // TODO: reply to
        }

        return try await requestObj(url: URL(string: FDUHOLE_BASE_URL + "/holes/\(holeId)/floors")!,
                             payload: ReplyConfig(content: content, specialTag: specialTag))
    }
    
    
    // MARK: Search
    
    // TODO: Implement new search API
    func searchKeyword(keyword: String, startFloor: Int = 0) async throws -> [THFloor] {
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/floors")!
        components.queryItems = [
            URLQueryItem(name: "s", value: keyword),
            URLQueryItem(name: "length", value: "10"),
            URLQueryItem(name: "start_floor", value: String(startFloor))
        ]
        return try await requestObj(url: components.url!)
    }
    
    
    // MARK: Report
    
    // TODO: Implement report paging
    /// List all reports.
    /// - Returns: A list of `THReport`
    func loadReportsList() async throws -> [THReport] {
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/reports")!
        components.queryItems = [ URLQueryItem(name: "category", value: "not_dealed") ]
        return try await requestObj(url: components.url!)
    }
    
    
    /// Add a report.
    /// - Parameters:
    ///   - floorId: Floor ID to report.
    ///   - reason: Report reason.
    func report(floorId: Int, reason: String) async throws {
        struct ReportConfig: Codable {
            let floorId: Int
            let reason: String
        }

        try await sendRequest(url: URL(string: FDUHOLE_BASE_URL + "/reports")!,
                              payload: ReportConfig(floorId: floorId, reason: reason))
    }
    
    
    /// Get a report by ID.
    /// - Parameter reportId: Report ID
    /// - Returns: A matching `THReport`.
    func getReportById(reportId: Int) async throws -> THReport {
        return try await requestObj(url: URL(string: FDUHOLE_BASE_URL + "/reports/\(reportId)")!)
    }
    
    
    /// Mark a report as dealt.
    /// - Parameter reportId: Report ID.
    /// - Returns: Dealt `THReport` struct.
    func dealReport(reportId: Int) async throws -> THReport {
        return try await requestObj(url: URL(string: FDUHOLE_BASE_URL + "/reports/\(reportId)")!,
                                    method: "DELETE")
    }
    
    
    // MARK: Tag
    
    
    /// Load all tags.
    func loadTags() async throws -> [THTag] {
        return try await requestObj(url: URL(string: FDUHOLE_BASE_URL + "/tags")!)
    }
    
    
    // MARK: Favorite
    // TODO: Modify favorites API
    
    /// Load favorites hole.
    /// - Returns: List of favorites hole.
    func loadFavorites() async throws -> [THHole] {
        return try await requestObj(url: URL(string: FDUHOLE_BASE_URL + "/user/favorites")!)
    }
    
    
    /// Set favorite status of a hole.
    /// - Parameters:
    ///   - holeId: Hole ID.
    ///   - add: Add or remove this hole from favorites.
    /// - Returns: List of favorites hole ID.
    func toggleFavorites(holeId: Int, add: Bool) async throws -> [Int] {
        struct FavoriteConfig: Codable {
            let holeId: Int
        }
        
        struct ServerResponse: Codable {
            let message: String
            var data: [Int]
        }
        
        let response: ServerResponse =
        try await requestObj(url: URL(string: FDUHOLE_BASE_URL + "/user/favorites")!,
                             payload: FavoriteConfig(holeId: holeId),
                             method: add ? "POST" : "DELETE")
        return response.data
    }
    
    
    // MARK: Penalty
    
    // TODO: Update penalty to new model
    /// Ban user.
    /// - Parameters:
    ///   - floor: floor to be banned.
    ///   - level: Ban level, range: 1-3.
    func addPenalty(floor: THFloor, level: Int) async throws {
        struct BanConfig: Codable {
            let penaltyLevel: Int
            let divisionId: Int
        }
        
        // get division ID
        let hole = try await loadHoleById(holeId: floor.holeId)
        let divisionId = hole.divisionId
        
        _ = try await sendRequest(url: URL(string: FDUHOLE_BASE_URL + "/penalty/\(floor.id)")!,
                                  payload: BanConfig(penaltyLevel: level, divisionId: divisionId))
    }
}
