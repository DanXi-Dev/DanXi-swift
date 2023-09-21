import Foundation
import SwiftyJSON

struct THRequests {
    
    // MARK: Division
    
    
    /// List all divisions.
    /// - Returns: A list of `THDivision`
    static func loadDivisions() async throws -> [THDivision] {
        return try await DXResponse(URL(string: FDUHOLE_BASE_URL + "/divisions")!)
    }
    
    
    /// Get division by ID.
    /// - Parameter id: Division ID.
    /// - Returns: The matching `THDivision`.
    static func getDivision(id: Int) async throws -> THDivision {
        return try await DXResponse(URL(string: FDUHOLE_BASE_URL + "/divisions/\(id)")!)
    }
    
    static func modifyDivision(id: Int, name: String, description: String, pinned: [Int]) async throws -> THDivision {
        struct ModifyConfig: Codable {
            let name: String
            let description: String
            let pinned: [Int]
        }
        
        let payload = ModifyConfig(name: name, description: description, pinned: pinned)
        return try await DXResponse(URL(string: FDUHOLE_BASE_URL + "/divisions/\(id)")!, payload: payload, method: "PUT")
    }
    
    
    // MARK: Hole
    
    
    /// List holes in a division.
    /// - Parameters:
    ///   - startTime: Updated time offset, default is now.
    ///   - divisionId: Division ID.
    /// - Returns: A list of holes.
    static func loadHoles(startTime: String? = nil, divisionId: Int, order: String = "time_updated") async throws -> [THHole] {
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/divisions/\(divisionId)/holes")!
        components.queryItems = [URLQueryItem(name: "order", value: order)]
        if let time = startTime {
            components.queryItems?.append(URLQueryItem(name: "offset", value: time))
            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        }
        return try await DXResponse(components.url!)
    }
    
    
    /// Create a hole.
    /// - Parameters:
    ///   - content: First floor content.
    ///   - divisionId: Division to post new hole.
    ///   - tags: Tags of the new hole.
    ///   - specialTag: First floor special tag, admin only.
    static func createHole(content: String, divisionId: Int, tags: [String], specialTag: String = "") async throws -> THHole {
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
        return try await DXResponse(URL(string: FDUHOLE_BASE_URL + "/divisions/\(divisionId)/holes")!,
                                     payload: payload)
    }
    
    
    /// Get hole by ID.
    /// - Parameter holeId: Hole ID.
    /// - Returns: The matching `THHole`.
    static func loadHoleById(holeId: Int) async throws -> THHole {
        do {
            let url = URL(string: FDUHOLE_BASE_URL + "/holes/\(holeId)")!
            return try await DXResponse(url)
        } catch let error as HTTPError {
            if error.code == 404 {
                throw DXError.holeNotExist(holeId: holeId)
            } else {
                throw error
            }
        }
    }
    
    
    /// List hole posted by user.
    /// - Parameter startTime: Updated time offset, default is now.
    /// - Returns: A list of holes.
    static func loadMyHoles(startTime: Date? = nil) async throws -> [THHole] {
        
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/users/me/holes")!
        if let time = startTime {
            components.queryItems = [URLQueryItem(name: "offset", value: time.ISO8601Format())]
            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        }
        return try await DXResponse(components.url!)
    }
    
    
    /// Modify hole.
    static func modifyHole(_ info: THHoleInfo) async throws -> THHole {
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/holes/\(info.holeId)")!
        return try await DXResponse(components.url!, payload: info, method: "PUT")
    }
    
    
    /// Hide a hole, only visible to admins.
    /// - Parameter holeId: Hole ID.
    static func deleteHole(holeId: Int) async throws {
        let url = URL(string: FDUHOLE_BASE_URL + "/holes/\(holeId)")!
        try await DXRequest(url, method: "DELETE")
    }
    
    
    /// Update hole view count.
    /// - Parameter holeId: Hole ID.
    static func updateViews(holeId: Int) async throws {
        let components = URLComponents(string: FDUHOLE_BASE_URL + "/holes/\(holeId)")!
        try await DXRequest(components.url!, method: "PATCH")
    }
    
    /// List holes by tag.
    /// - Parameters:
    ///   - tagName: Tag name.
    ///   - startTime: update time offset
    /// - Returns: List of `THHole`.
    static func listHoleByTag(tagName: String, startTime: String? = nil) async throws -> [THHole] {
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/holes")!
        components.queryItems = [URLQueryItem(name: "tag", value: tagName)]
        if let time = startTime {
            components.queryItems?.append(URLQueryItem(name: "start_time", value: time))
        }
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        return try await DXResponse(components.url!)
    }
    
    
    // MARK: Floor
    
    
    /// Get a floor by ID.
    /// - Parameter floorId: Floor ID.
    static func loadFloorById(floorId: Int) async throws -> THFloor {
        do {
            return try await DXResponse(URL(string: FDUHOLE_BASE_URL + "/floors/\(floorId)")!)
        } catch let error as HTTPError {
            if error.code == 404 {
                throw DXError.floorNotExist(floorId: floorId)
            } else {
                throw error
            }
        }
    }
    
    
    /// Modify a floor.
    /// - Parameters:
    ///   - content: New content.
    ///   - floorId: Floor ID.
    ///   - specialTag: Optional, special tag, admin only.
    /// - Returns: Modified floor.
    static func modifyFloor(content: String,
                            floorId: Int,
                            specialTag: String = "",
                            fold: String = "") async throws -> THFloor {
        struct AdminEditConfig: Codable {
            let content: String
            let specialTag: String
            let foldV2: String
        }
        
        struct EditConfig: Codable {
            let content: String
        }
        
        let isAdmin = !fold.isEmpty || !specialTag.isEmpty
        if isAdmin {
            return try await DXResponse(URL(string: FDUHOLE_BASE_URL + "/floors/\(floorId)")!,
                                        payload: AdminEditConfig(content: content, specialTag: specialTag, foldV2: fold),
                                        method: "PUT")
        } else {
            return try await DXResponse(URL(string: FDUHOLE_BASE_URL + "/floors/\(floorId)")!,
                                        payload: EditConfig(content: content),
                                        method: "PUT")
        }
    }
    
    
    /// Delete a floor.
    /// - Parameters:
    ///   - floorId: Floor ID to be deleted.
    ///   - reason: Delete reason, admin only.
    /// - Returns: Deleted floor struct.
    static func deleteFloor(floorId: Int, reason: String = "") async throws -> THFloor {
        struct DeleteConfig: Codable {
            let deleteReason: String
        }
        
        return try await DXResponse(URL(string: FDUHOLE_BASE_URL + "/floors/\(floorId)")!,
                                    payload: DeleteConfig(deleteReason: reason), method: "DELETE")
    }
    
    
    /// Get a floor's history.
    /// - Parameter floorId: Floor ID.
    static func loadFloorHistory(floorId: Int) async throws -> [THHistory] {
        return try await DXResponse(URL(string: FDUHOLE_BASE_URL + "/floors/\(floorId)/history")!)
    }
    
    
    /// Like or unlike a floor.
    /// - Parameters:
    ///   - floorId: Floor ID.
    ///   - like: Set like status, 1 is like, 0 is reset, -1 is dislike.
    /// - Returns: Modified floor.
    static func like(floorId: Int, like: Int) async throws -> THFloor {
        return try await DXResponse(URL(string: FDUHOLE_BASE_URL +
                                             "/floors/\(floorId)/like/\(like)")!,
                                    method: "POST")
    }
    
    
    /// Restore a floor from a history version.
    /// - Parameters:
    ///   - floorId: Floor ID.
    ///   - historyId: History ID.
    ///   - restoreReason: Restore reason.
    /// - Returns: Restored floor.
    static func restoreFloor(floorId: Int, historyId: Int, restoreReason: String) async throws -> THFloor {
        struct RestoreConfig: Codable {
            let restoreReason: String
        }
        
        return try await DXResponse(URL(string: FDUHOLE_BASE_URL + "/floors/\(floorId)/restore/\(historyId)")!,
                                    payload: RestoreConfig(restoreReason: restoreReason))
    }
    
    
    /// List floors from a hole.
    /// - Parameters:
    ///   - holeId: Hole ID.
    ///   - startFloor: Start floor offset.
    /// - Returns: A list of floors.
    static func loadFloors(holeId: Int, startFloor: Int) async throws -> [THFloor] {
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/holes/\(holeId)/floors")!
        components.queryItems = [
            URLQueryItem(name: "offset", value: String(startFloor)),
            URLQueryItem(name: "order_by", value: "id")
            // TODO: sort
        ]
        return try await DXResponse(components.url!)
    }
    
    
    /// Load all floors within a given hole. (Undocumented API)
    /// - Parameter holeId: Hole ID.
    /// - Returns: A list of floors.
    static func loadAllFloors(holeId: Int) async throws -> [THFloor] {
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/floors")!
        components.queryItems = [
            URLQueryItem(name: "hole_id", value: String(holeId)),
            URLQueryItem(name: "start_floor", value: "0"),
            URLQueryItem(name: "length", value: "0")
        ]
        return try await DXResponse(components.url!)
    }
    
    
    /// Create a floor.
    /// - Parameters:
    ///   - content: Floor content.
    ///   - holeId: Hole ID.
    ///   - specialTag: Optional, special tag, admin only.
    /// - Returns: Created floor.
    static func createFloor(content: String, holeId: Int, specialTag: String = "") async throws -> THFloor {
        struct ReplyConfig: Codable {
            let content: String
            let specialTag: String
            // TODO: reply to
        }

        return try await DXResponse(URL(string: FDUHOLE_BASE_URL + "/holes/\(holeId)/floors")!,
                             payload: ReplyConfig(content: content, specialTag: specialTag))
    }
    
    
    // MARK: Search
    
    // TODO: Implement new search API
    static func searchKeyword(keyword: String, startFloor: Int = 0) async throws -> [THFloor] {
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/floors")!
        components.queryItems = [
            URLQueryItem(name: "s", value: keyword),
            URLQueryItem(name: "length", value: "10"),
            URLQueryItem(name: "start_floor", value: String(startFloor))
        ]
        return try await DXResponse(components.url!)
    }
    
    
    // MARK: Report
    
    
    /// Load a list of reports
    /// - Parameters:
    ///   - offset: Report list offset.
    ///   - range: Report type, 0: not dealt; 1: dealt; 2: all
    /// - Returns: Report list.
    static func loadReports(offset: Int, range: Int) async throws -> [THReport] {
        var components = URLComponents(string: FDUHOLE_BASE_URL + "/reports")!
        components.queryItems = [
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "range", value: String(range))
        ]
        return try await DXResponse(components.url!)
    }
    
    
    /// Add a report.
    /// - Parameters:
    ///   - floorId: Floor ID to report.
    ///   - reason: Report reason.
    static func report(floorId: Int, reason: String) async throws {
        struct ReportConfig: Codable {
            let floorId: Int
            let reason: String
        }

        try await DXRequest(URL(string: FDUHOLE_BASE_URL + "/reports")!,
                              payload: ReportConfig(floorId: floorId, reason: reason))
    }
    
    
    /// Get a report by ID.
    /// - Parameter reportId: Report ID
    /// - Returns: A matching `THReport`.
    static func getReportById(reportId: Int) async throws -> THReport {
        return try await DXResponse(URL(string: FDUHOLE_BASE_URL + "/reports/\(reportId)")!)
    }
    
    
    /// Mark a report as dealt.
    /// - Parameter reportId: Report ID.
    /// - Returns: Dealt `THReport` struct.
    static func dealReport(reportId: Int) async throws -> THReport {
        return try await DXResponse(URL(string: FDUHOLE_BASE_URL + "/reports/\(reportId)")!,
                                    method: "DELETE")
    }
    
    
    // MARK: Tag
    
    
    /// Load all tags.
    static func loadTags() async throws -> [THTag] {
        return try await DXResponse(URL(string: FDUHOLE_BASE_URL + "/tags")!)
    }
    
    
    // MARK: Favorite
    
    /// Load favorites hole.
    /// - Returns: List of favorites hole.
    static func loadFavorites() async throws -> [THHole] {
        return try await DXResponse(URL(string: FDUHOLE_BASE_URL + "/user/favorites")!)
    }
    
    
    /// Load favorites hole IDs.
    /// - Returns: List of favorite hole ID.
    static func loadFavoritesIds() async throws -> [Int] {
        struct FavoriteResponse: Codable {
            let data: [Int]
        }
        
        var component = URLComponents(string: FDUHOLE_BASE_URL + "/user/favorites")!
        component.queryItems = [URLQueryItem(name: "plain", value: "true")]
        let response: FavoriteResponse = try await DXResponse(component.url!)
        return response.data
    }
    
    
    /// Modify favorites.
    /// - Parameter holeIds: New hole IDs.
    /// - Returns: List of favorite hole ID.
    static func modifyFavorites(holeIds: [Int]) async throws -> [Int] {
        struct FavoriteConfig: Codable {
            let holeIds: [Int]
        }
        
        struct ReturnConfig: Codable {
            let data: [Int]
            let message: String
        }
        
        let payload = FavoriteConfig(holeIds: holeIds)
        let response: ReturnConfig = try await DXResponse(URL(string: FDUHOLE_BASE_URL + "/user/favorites")!,
                                                          payload: payload,
                                                          method: "PUT")
        return response.data
    }
    
    /// Set favorite status of a hole.
    /// - Parameters:
    ///   - holeId: Hole ID.
    ///   - add: Add or remove this hole from favorites.
    /// - Returns: List of favorites hole ID.
    static func toggleFavorites(holeId: Int, add: Bool) async throws -> [Int] {
        struct FavoriteConfig: Codable {
            let holeId: Int
        }
        
        struct ServerResponse: Codable {
            let message: String
            var data: [Int]
        }
        
        let response: ServerResponse =
        try await DXResponse(URL(string: FDUHOLE_BASE_URL + "/user/favorites")!,
                             payload: FavoriteConfig(holeId: holeId),
                             method: add ? "POST" : "DELETE")
        return response.data
    }
    
    
    // MARK: Penalty
    
    
    /// Ban user.
    /// - Parameters:
    ///   - days: Penalty duration.
    ///   - reason: Reason.
    static func addPenalty(_ floorId: Int, _ days: Int, reason: String = "") async throws {
        struct BanConfig: Codable {
            let days: Int
            let reason: String
        }
        
        let payload = BanConfig(days: days, reason: reason)
        try await DXRequest(URL(string: FDUHOLE_BASE_URL + "/penalty/\(floorId)")!,
                                  payload: payload)
    }
    
    /// Get punishment history of a floor's poster.
    /// - Parameter floorId: Floor ID.
    /// - Returns: A list of reasons.
    static func loadPunishmenthistory(_ floorId: Int) async throws -> [String] {
        return try await DXResponse(URL(string: FDUHOLE_BASE_URL + "/floors/\(floorId)/punishment")!)
    }
    
    // MARK: Messages
    
    static func loadMessages() async throws -> [THMessage] {
        return try await DXResponse(URL(string: FDUHOLE_BASE_URL + "/messages")!)
    }
    
    static func sendMessage(message: String, recipients: [Int]) async throws {
        struct SendConfig: Codable {
            let description: String
            let recipients: [Int]
        }
        
        let payload = SendConfig(description: message, recipients: recipients)
        try await DXRequest(URL(string: FDUHOLE_BASE_URL + "/messages")!, payload: payload)
    }
    
    // MARK: Images
    
    static func uploadImage(_ imageData: Data) async throws -> URL {
        func formParam(_ boundaryData: Data, key: String, value: String) -> Data {
            var data = Data()
            data.append(boundaryData)
            data.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: String.Encoding.utf8)!)
            data.append(value.data(using: String.Encoding.utf8)!)
            return data
        }
        
        // prepare URL requst and metadata
        let url = URL(string: "https://image.fduhole.com/json")!
        let boundary = UUID().uuidString
        let boundaryData = "\r\n--\(boundary)\r\n".data(using: String.Encoding.utf8)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // append text values
        var data = Data()
        data.append(formParam(boundaryData, key: "type", value: "file"))
        data.append(formParam(boundaryData, key: "action", value: "upload"))
        data.append(formParam(boundaryData, key: "auth_token", value: "123456789"))
        
        // append image data
        data.append(boundaryData)
        data.append("Content-Disposition: form-data; name=\"source\"; filename=\"image.png\"\r\n".data(using: String.Encoding.utf8)!)
        data.append("Content-Type: image/png\r\n\r\n".data(using: String.Encoding.utf8)!)
        data.append(imageData)
        data.append("\r\n--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
        
        // request and process response
        let (responseData, _) = try await URLSession.shared.upload(for: request, from: data)
        guard let responseObject = try? JSON(data: responseData),
              let urlString = responseObject["image", "url"].string,
              let url = URL(string: urlString) else {
            throw ParseError.invalidResponse
        }
        return url
    }
}
