import Foundation
import KeychainAccess
import UserNotifications
import SwiftyJSON
import UIKit
import Disk

// MARK: Models

@MainActor
class DXModel: ObservableObject {
    
    // MARK: - General
    
    static var shared = DXModel()
    
    init() {
        // initialize token from keychain
        guard let data = keychain[data: "token"] else { return }
        guard let token = try? JSONDecoder().decode(Token.self, from: data) else { return }
        self.token = token
        self.isLogged = true
    }
    
    func clearAll() {
        self.user = nil
        THModel.shared.clearAll()
        DKModel.shared.clearAll()
    }
    
    // MARK: - Authentication
    
    let keychain = Keychain(service: "com.fduhole.danxi")
    @Published var isLogged: Bool = false
    var token: Token? {
        didSet {
            self.isLogged = token != nil
            if let token = token {
                keychain[data: "token"] = try! JSONEncoder().encode(token)
            } else {
                keychain["token"] = nil
            }
        }
    }
    
    func login(username: String, password: String) async throws {
        token = try await DXRequests.login(username: username, password: password)
    }
    
    func resetPassword(email: String, password: String, verification: String, create: Bool) async throws {
        token = try await DXRequests.register(email: email, password: password, verification: verification, create: false)
    }
    
    func logout() {
        isLogged = false
        token = nil
        clearAll()
        Task {
            guard let deviceId = UIDevice.current.identifierForVendor?.uuidString else { return }
            try await DXRequests.deleteNotificationToken(deviceId: deviceId)
            try await DXRequests.logout()
        }
    }
    
    func refreshToken() async throws {
        token = try await DXRequests.refreshToken()
    }
    
    // MARK: - Notifications
    
    private let defaults = UserDefaults.standard
    
    private func tokenDidChange(_ token: String) -> Bool {
        guard let oldToken = defaults.string(forKey: "notification-token") else {
            return true
        }
        return token != oldToken
    }

    func receiveToken(_ tokenData: Data, _ deviceId: UUID) {
        guard isLogged else { return }
        let token: String = tokenData.map { String(format: "%.2hhx", $0) }.joined()
        guard tokenDidChange(token) else {
            return
        }
        
        Task {
            try await DXRequests.uploadNotificationToken(deviceId: deviceId.uuidString, token: token)
            defaults.set(token, forKey: "notification-token")
        }
    }
    
    // MARK: User
    
    @Published var user: DXUser?
    
    var isAdmin: Bool {
        user?.isAdmin ?? false
    }
    
    func loadUser() async throws -> DXUser {
        let user = try await DXRequests.loadUserInfo()
        self.user = user
        return user
    }
    
    // MARK: Remote Extra
    
    func loadExtra() async {
        do {
            let info = try await DXRequests.getInfo()
            guard let extra = info.filter({ $0.type == -5 }).first,
                  let data = extra.content.data(using: String.Encoding.utf8),
                  let json = try? JSON(data: data) else {
                return
            }
            
            if let bannerData = try? json["banners"].rawData(),
               let banners = try? JSONDecoder().decode([DXBanner].self, from: bannerData) {
                THModel.shared.banners = banners
            }
            
            if let timetableData = try? json["timetable", "fdu_ug"].rawData(),
               let timetable = try? JSONDecoder().decode([Timetable].self, from: timetableData) {
                FDCalendarModel.timetables = timetable
                FDCalendarModel.timetablePublisher.send(timetable)
            }
        } catch {
            
        }
        
    }
}

@MainActor
class THModel: ObservableObject {
    static var shared = THModel()
    
    @Published var favoriteIds: [Int] = []
    @Published var divisions: [THDivision] = []
    @Published var tags: [THTag] = []
    @Published var loaded = false
    @Published var banners: [DXBanner] = []
    @Published var browseHistory: [THBrowseHistory] = []
    
    func loadAll() async throws {
        // use async-let to parallel load
        async let favoriteIds = try await THRequests.loadFavoritesIds()
        async let divisions = try await THRequests.loadDivisions()
        async let tags = try await loadTags()
        self.favoriteIds = try await favoriteIds
        self.divisions = try await divisions
        self.tags = try await tags
        
        if let browseHistory = try? Disk.retrieve("fduhole/history.json", from: .applicationSupport, as: [THBrowseHistory].self) {
            self.browseHistory = browseHistory
        }
        
        if self.divisions.isEmpty {
            throw ParseError.invalidResponse
        }
        loaded = true
    }
    
    func clearAll() {
        favoriteIds = []
        divisions = []
        tags = []
        loaded = false
        
        // remove stored tags on disk
        Task {
            try Disk.remove("fduhole/tags.json", from: .applicationSupport)
            try Disk.remove("fduhole/history.json", from: .applicationSupport)
        }
    }
    
    func refreshDivisions() async throws {
        self.divisions = try await THRequests.loadDivisions()
    }
    
    func loadTags() async throws -> [THTag] {
        if let tagsData = try? Disk.retrieve("fduhole/tags.json", from: .applicationSupport, as: CachedData<[THTag]>.self),
           let tags = tagsData.validValue {
            return tags
        }
        
        let tags = try await THRequests.loadTags()
        Task {
            let cache = CachedData(value: tags)
            cache.store(path: "fduhole/tags.json")
        }
        
        return tags
    }
    
    func isFavorite(_ id: Int) -> Bool {
        favoriteIds.contains(id)
    }
    
    func toggleFavorite(_ id: Int) async throws {
        self.favoriteIds = try await THRequests.toggleFavorites(holeId: id, add: !isFavorite(id))
    }
    
    func loadFavoriteIds() async throws {
        self.favoriteIds = try await THRequests.loadFavoritesIds()
    }
    
    func appendHistory(hole: THHole) {
        let history = THBrowseHistory(hole)
        browseHistory.removeAll { $0.id == history.id }
        browseHistory.insert(history, at: 0)
        if browseHistory.count > 200 {
            browseHistory.removeSubrange(200...) // only keep recent 200 records
        }

        Task {
            // save to disk, perform on background task
            try Disk.save(browseHistory, to: .applicationSupport, as: "fduhole/history.json")
        }
    }
    
    func clearHistory() {
        browseHistory = []
        Task {
            try Disk.save(browseHistory, to: .applicationSupport, as: "fduhole/history.json")
        }
    }
}

@MainActor
class DKModel: ObservableObject {
    static var shared = DKModel()
    
    @Published var courses: [DKCourseGroup] = []
    
    fileprivate struct CourseCache: Codable {
        let courses: [DKCourseGroup]
        let hash: String
    }
    
    func loadAll() async throws {
        guard self.courses.isEmpty else { return }
        
        let hash = try await DKRequests.loadCourseHash()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let cached = try? Disk.retrieve("fduhole/courses.json", from: .applicationSupport, as: CourseCache.self) {
            if cached.hash == hash {
                self.courses = cached.courses
                return
            }
        }
        
        let courses = try await DKRequests.loadCourseGroups()
        self.courses = courses
        Task {
            let cache = CourseCache(courses: courses, hash: hash)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            try Disk.save(cache, to: .applicationSupport, as: "fduhole/courses.json", encoder: encoder)
        }
    }
    
    func clearAll() {
        self.courses = []
        Task {
            try Disk.remove("fduhole/courses.json", from: .applicationSupport)
        }
    }
}

// MARK: Disk Cache

fileprivate struct CachedData<V: Codable>: Codable {
    let value: V
    let expireAt: Date
    
    init(value: V, interval: TimeInterval = 60 * 60 * 24) {
        self.value = value
        self.expireAt = Date(timeIntervalSinceNow: interval)
    }
    
    var expired: Bool {
        return expireAt < Date.now
    }
    
    var validValue: V? {
        return expired ? nil : value
    }
    
    func store(path: String) {
        do {
            try Disk.save(self, to: .applicationSupport, as: path)
        } catch {
            
        }
    }
}
