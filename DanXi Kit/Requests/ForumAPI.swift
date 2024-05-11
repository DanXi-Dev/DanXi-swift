import Foundation

public enum ForumAPI {
    
    private struct ServerResponse: Codable {
        let data: [Int]
    }
    
    // MARK: - Divisions
    
    public static func getDivisions() async throws -> [Division] {
        return try await requestWithResponse("/divisions", base: forumURL)
    }
    
    public static func addDivision(description: String, name: String) async throws -> Division {
        let payload = ["description": description, "name": name]
        return try await requestWithResponse("/divisions", base: forumURL, payload: payload)
    }
    
    public static func getDivision(id: Int) async throws -> Division {
        return try await requestWithResponse("/divisions/\(id)", base: forumURL)
    }
    
    public static func modifyDivision(id: Int, description: String, name: String, pinned: [Int]) async throws -> Division {
        let payload: [String: Any] = ["description": description, "name": name, "pinned": pinned]
        return try await requestWithResponse("/divisions/\(id)", base: forumURL, payload: payload, method: "PUT")
    }
    
    public static func deleteDivision(id: Int, moveTo: Int) async throws {
        let payload = ["move": moveTo]
        try await requestWithoutResponse("/divisions/\(id)", base: forumURL, payload: payload, method: "DELETE")
    }
    
    // MARK: - Holes
    
    public static func listHolesInDivision(divisionId: Int, startTime: Date? = nil, order: String = "time_updated") async throws -> [Hole] {
        var params = ["order": order]
        if let time = startTime {
            params["offset"] = time.ISO8601Format()
        }
        return try await requestWithResponse("/divisions/\(divisionId)/holes", base: forumURL, params: params)
    }
    
    public static func createHole(content: String, divisionId: Int, tags: [String], specialTag: String = "") async throws -> Hole {
        let tagsPayload = tags.map { ["name": $0] }
        let payload: [String: Any] = ["content": content, "special_tag": specialTag, "tags": tagsPayload]
        return try await requestWithResponse("/divisions/\(divisionId)/holes", base: forumURL, payload: payload)
    }
    
    public static func getHole(id: Int) async throws -> Hole {
        return try await requestWithResponse("/holes/\(id)", base: forumURL)
    }
    
    public static func modifyHole(id: Int, divisionId: Int? = nil, lock: Bool? = nil, tags: [String], hidden: Bool? = nil) async throws -> Hole {
        var payload: [String: Any] = ["tags": tags.map { ["name": $0] }]
        if let divisionId {
            payload["division_id"] = divisionId
        }
        if let lock {
            payload["lock"] = lock
        }
        if let hidden {
            payload["unhidden"] = !hidden
        }
        return try await requestWithResponse("/holes/\(id)", base: forumURL, payload: payload, method: "PUT")
    }
    
    public static func deleteHole(id: Int) async throws {
        try await requestWithoutResponse("/holes/\(id)", base: forumURL, method: "DELETE")
    }
    
    public static func updateHoleViews(id: Int) async throws {
        try await requestWithoutResponse("/holes/\(id)", base: forumURL, method: "PATCH")
    }
    
    public static func listHolesByTag(tagName: String, startTime: Date? = nil) async throws -> [Hole] {
        var params = ["tag": tagName]
        if let time = startTime {
            params["start_time"] = time.ISO8601Format()
        }
        return try await requestWithResponse("/holes", base: forumURL, params: params)
    }
    
    public static func listMyHoles(startTime: Date? = nil) async throws -> [Hole] {
        var params: [String: String] = [:]
        if let time = startTime {
            params["offset"] = time.ISO8601Format()
        }
        return try await requestWithResponse("/users/me/holes", base: forumURL, params: params)
    }
    
    // MARK: - Floors
    
    public static func getFloor(id: Int) async throws -> Floor {
        return try await requestWithResponse("/floors/\(id)", base: forumURL)
    }
    
    public static func modifyFloor(id: Int, content: String, specialTag: String = "", fold: String = "") async throws -> Floor {
        let payload: [String: Any] = ["content": content, "special_tag": specialTag, "fold_v2": fold]
        return try await requestWithResponse("/floors/\(id)", base: forumURL, payload: payload, method: "PUT")
    }
    
    public static func deleteFloor(id: Int, reason: String = "") async throws -> Floor {
        let payload = ["delete_reason": reason]
        return try await requestWithResponse("/floors/\(id)", base: forumURL, payload: payload, method: "DELETE")
    }
    
    public static func listFloorHistory(id: Int) async throws -> [FloorHistory] {
        return try await requestWithResponse("/floors/\(id)/history", base: forumURL)
    }
    
    public static func listFloorPunishmentStatus(id: Int) async throws -> [Int: Date] {
        return try await requestWithResponse("/floors/\(id)/user_silence", base: forumURL)
    }
    
    public static func likeFloor(id: Int, like: Int) async throws -> Floor {
        return try await requestWithResponse("/floors/\(id)/like/\(like)", base: forumURL, method: "POST")
    }
    
    public static func restoreFloor(id: Int, historyId: Int, reason: String) async throws -> Floor {
        let payload = ["restore_reason": reason]
        return try await requestWithResponse("/floors/\(id)/restore/\(historyId)", base: forumURL, payload: payload)
    }
    
    public static func listFloorsInHole(holeId: Int, startFloor: Int, size: Int? = nil) async throws -> [Floor] {
        var params = ["offset": "\(startFloor)", "order_by": "id"]
        if let size {
            params["size"] = String(size)
        }
        return try await requestWithResponse("/holes/\(holeId)/floors", base: forumURL, params: params)
    }
    
    public static func listAllFloors(holeId: Int) async throws -> [Floor] {
        let params = ["hole_id": String(holeId), "start_floor": "0", "length": "0"]
        return try await requestWithResponse("/floors", base: forumURL, params: params)
    }
    
    public static func listMyFloors(offset: Int) async throws -> [Floor] {
        let params = ["offset": String(offset)]
        return try await requestWithResponse("/users/me/floors", base: forumURL, params: params)
    }
    
    public static func createFloor(content: String, holeId: Int, specialTag: String = "") async throws -> Floor {
        let payload = ["content": content, "specialTag": specialTag]
        return try await requestWithResponse("/holes/\(holeId)/floors", base: forumURL, payload: payload)
    }
    
    public static func searchFloor(keyword: String, accurate: Bool? = nil, offset: Int) async throws -> [Floor] {
        var params = ["search": keyword, "offset": String(offset)]
        if let accurate {
            params["accurate"] = accurate ? "true" : "false"
        }
        return try await requestWithResponse("/floors/search", base: forumURL, params: params)
    }
    
    // MARK: - Penalty
    
    public static func listFloorPunishmentHistory(id: Int) async throws -> [String] {
        return try await requestWithResponse("/floors/\(id)/punishment", base: forumURL)
    }
    
    public static func penaltyForFloor(id: Int, reason: String, days: Int, division: Int? = nil) async throws {
        var payload: [String: Any] = ["reason": reason, "days": days]
        if let division {
            payload["division"] = division
        }
        try await requestWithoutResponse("/penalty/\(id)", base: forumURL, payload: payload)
    }
    
    // MARK: - Reports
    
    public static func listReports(offset: Int, type: Int) async throws -> [Report] {
        let params = ["offset": String(offset), "range": String(type)]
        return try await requestWithResponse("/reports", base: forumURL, params: params)
    }
    
    public static func createReport(floorId: Int, reason: String) async throws {
        let payload: [String: Any] = ["floor_id": floorId, "reason": reason]
        try await requestWithoutResponse("/reports", base: forumURL, payload: payload)
    }
    
    public static func getReport(id: Int) async throws -> Report {
        return try await requestWithResponse("/reports/\(id)", base: forumURL)
    }
    
    public static func dealReport(id: Int) async throws -> Report {
        return try await requestWithResponse("/reports/\(id)", base: forumURL, method: "DELETE")
    }
    
    // MARK: - Tags
    
    public static func listAllTags() async throws -> [Tag] {
        return try await requestWithResponse("/tags", base: forumURL)
    }
    
    // MARK: - Favorites
    
    public static func listFavorites() async throws -> [Hole] {
        return try await requestWithResponse("/user/favorites", base: forumURL)
    }
    
    public static func listFavoriteHoleIds() async throws -> [Int] {
        let response: ServerResponse = try await requestWithResponse("/user/favorites", base: forumURL, params: ["plain": "true"])
        return response.data
    }
    
    public static func modifyFavorites(holeIds: [Int]) async throws -> [Int] {
        let payload = ["holeIds": holeIds]
        let response: ServerResponse = try await requestWithResponse("/user/favorites", base: forumURL, payload: payload, method: "PUT")
        return response.data
    }
    
    public static func toggleFavorite(holeId: Int, add: Bool) async throws -> [Int] {
        let method = add ? "POST" : "DELETE"
        let payload = ["hole_id": holeId]
        let response: ServerResponse = try await requestWithResponse("/user/favorites", base: forumURL, payload: payload, method: method)
        return response.data
    }
    
    // MARK: - Subscriptions
    
    public static func listSubscriptionIds() async throws -> [Int] {
        let response: ServerResponse = try await requestWithResponse("/users/subscriptions", base: forumURL, params: ["plain": "true"])
        return response.data
    }
    
    public static func listSubscriptions() async throws -> [Hole] {
        return try await requestWithResponse("/users/subscriptions", base: forumURL)
    }
    
    public static func addSubscription(holeId: Int) async throws -> [Int] {
        let payload = ["hole_id": holeId]
        let response: ServerResponse = try await requestWithResponse("/users/subscriptions", base: forumURL, payload: payload, method: "POST")
        return response.data
    }
    
    public static func deleteSubscription(holeId: Int) async throws -> [Int] {
        let payload = ["hole_id": holeId]
        let response: ServerResponse = try await requestWithResponse("/users/subscription", base: forumURL, payload: payload, method: "DELETE")
        return response.data
    }
    
    // MARK: - Messages
    
    public static func listMessages() async throws -> [Message] {
        return try await requestWithResponse("/messages", base: forumURL)
    }
    
    public static func sendMessage(content: String, recipients: [Int]) async throws {
        let payload: [String: Any] = ["description": content, "recipients": recipients]
        try await requestWithoutResponse("/messages", base: forumURL, payload: payload)
    }
    
    // MARK: - Profile
    
    public static func getProfile() async throws -> Profile {
        return try await requestWithResponse("/users/me", base: forumURL)
    }
    
    public static func updateUserSettings(userId: Int, notificationConfiguration: [String]? = nil, showFoldedConfiguration: String? = nil) async throws -> Profile {
        var configuration: [String: Any] = [:]
        if let notificationConfiguration {
            configuration["notify"] = notificationConfiguration
        }
        if let showFoldedConfiguration {
            configuration["show_folded"] = showFoldedConfiguration
        }
        let payload: [String: Any] = ["config": configuration]
        return try await requestWithResponse("/users/\(userId)", base: forumURL, payload: payload, method: "PUT")
    }
    
    public static func uploadNotificationToken(deviceId: String, token: String) async throws {
        guard let packageName = Bundle.main.bundleIdentifier else { return }
        let payload = ["service": "apns", "deviceId": deviceId, "token": token, "package_name": packageName]
        try await requestWithoutResponse("/users/push-tokens", base: forumURL, payload: payload)
    }
    
    public static func deleteNotificationToken(deviceId: String) async throws {
        let payload = ["deviceId": deviceId]
        try await requestWithoutResponse("/users/push-tokens", base: forumURL, payload: payload, method: "DELETE")
    }
    
    // MARK: - Sensitive Content
    
    public static func listSensitive(startTime: Date = Date.now, open: Bool = true, order: String = "time_created") async throws -> [Sensitive] {
        let params = ["open": open ? "true" : "false",
                      "offset": startTime.ISO8601Format(),
                      "order_by": order]
        return try await requestWithResponse("/floors/_sensitive", base: forumURL, params: params)
    }
    
    public static func setFloorSensitive(floorId: Int, sensitive: Bool) async throws {
        let payload = ["is_actual_sensitive": sensitive]
        try await requestWithoutResponse("/floors/\(floorId)/_sensitive", base: forumURL, payload: payload, method: "PUT")
    }
}
