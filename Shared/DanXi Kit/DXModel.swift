import Foundation
import KeychainAccess
import UserNotifications
import UIKit

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
        self.cachedTags = nil
        self.coursesCache = nil
        self.courses = []
        self.divisions = []
        self.favoriteIds = []
    }
    
    // MARK: - Util
    
    var forumLoaded = false
    
    func loadForum() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                if await self.cachedTags == nil {
                    try await self.loadTags()
                }
            }
            group.addTask {
                if await self.user == nil {
                    try await self.loadUser()
                }
            }
            group.addTask {
                if await self.divisions.isEmpty {
                    try await self.loadDivisions()
                }
            }
            group.addTask {
                if await self.favoriteIds.isEmpty {
                    try await self.loadFavoriteIds()
                }
            }
            try await group.waitForAll()
            forumLoaded = true
        }
    }
    
    func loadCurriculum() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                if await self.courses.isEmpty {
                    try await self.loadCourses()
                }
            }
            group.addTask {
                if await self.user == nil {
                    try await self.loadUser()
                }
            }
            try await group.waitForAll()
        }
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
            do {
                guard let deviceId = UIDevice.current.identifierForVendor?.uuidString else { return }
                try await DXRequests.deleteNotificationToken(deviceId: deviceId)
                try await DXRequests.logout()
            } catch {
                
            }
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
    
    // MARK: - Disk Cache
    
    // MARK: User
    
    @DiskCache("fduhole/user.json") var user: DXUser?
    var isAdmin: Bool {
        user?.isAdmin ?? false
    }
    
    func loadUser() async throws {
        self.user = try await DXRequests.loadUserInfo()
    }
    
    // MARK: Tags
    
    @DiskCache("fduhole/tags.json") var cachedTags: [THTag]?
    var tags: [THTag] {
        return cachedTags ?? []
    }
    func loadTags() async throws {
        cachedTags = try await THRequests.loadTags()
    }
    
    // MARK: Courses
    
    struct DKCourseCache: Codable {
        let hash: String
        let courses: [DKCourseGroup]
    }
    
    @DiskCache("fduhole/courses.json", expire: nil) var coursesCache: DKCourseCache?
    @Published var courses: [DKCourseGroup] = []
    
    func loadCourses() async throws {
        let hash = try await DKRequests.loadCourseHash()
        if let coursesCache = coursesCache {
            if coursesCache.hash == hash {
                self.courses = coursesCache.courses
                return
            }
        }
        let courses = try await DKRequests.loadCourseGroups()
        coursesCache = DKCourseCache(hash: hash, courses: courses)
        self.courses = courses
    }
    
    // MARK: - Memory Cache
    
    // MARK: Division
    
    @Published var divisions: [THDivision] = []
    
    func loadDivisions() async throws {
        self.divisions = try await THRequests.loadDivisions()
    }
    
    // MARK: Favorites
    
    @Published var favoriteIds: [Int] = []
    
    func isFavorite(_ id: Int) -> Bool {
        return favoriteIds.contains(id)
    }
    
    func loadFavoriteIds() async throws {
        self.favoriteIds = try await THRequests.loadFavoritesIds()
    }
    
    func toggleFavorite(_ id: Int) async throws {
        self.favoriteIds = try await THRequests.toggleFavorites(holeId: id, add: !isFavorite(id))
    }
}
