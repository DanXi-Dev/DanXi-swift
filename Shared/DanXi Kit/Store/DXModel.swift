import Foundation

class DXModel: ObservableObject {
    // MARK: - General
    static var shared = DXModel()
    private init() {
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
                if self.cachedTags == nil {
                    try await self.loadTags()
                }
            }
            group.addTask {
                if self.user == nil {
                    try await self.loadUser()
                }
            }
            group.addTask {
                if self.divisions.isEmpty {
                    try await self.loadDivisions()
                }
            }
            group.addTask {
                if self.favoriteIds.isEmpty {
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
                if self.courses.isEmpty {
                    try await self.loadCourses()
                }
            }
            group.addTask {
                if self.user == nil {
                    try await self.loadUser()
                }
            }
            try await group.waitForAll()
        }
    }
    
    // MARK: - DIsk Cache
    
    // MARK: User
    
    @DiskCache("fduhole/user.json") var user: DXUser?
    var isAdmin: Bool {
        user?.isAdmin ?? false
    }
    
    func loadUser() async throws {
        self.user = try await DXAuthRequests.loadUserInfo()
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
                Task { @MainActor in self.courses = coursesCache.courses }
                return
            }
        }
        let courses = try await DKRequests.loadCourseGroups()
        coursesCache = DKCourseCache(hash: hash, courses: courses)
        Task { @MainActor in self.courses = courses }
    }
    
    // MARK: - Memory Cache
    
    // MARK: Division
    
    @Published var divisions: [THDivision] = []
    
    func loadDivisions() async throws {
        let divisions = try await THRequests.loadDivisions()
        Task { @MainActor in self.divisions = divisions }
    }
    
    // MARK: Favorites
    
    @Published var favoriteIds: [Int] = []
    
    func isFavorite(_ id: Int) -> Bool {
        return favoriteIds.contains(id)
    }
    
    func loadFavoriteIds() async throws {
        let favoriteIds = try await THRequests.loadFavoritesIds()
        Task { @MainActor in self.favoriteIds = favoriteIds }
    }
    
    func toggleFavorite(_ id: Int) async throws {
        let ids = try await THRequests.toggleFavorites(holeId: id, add: !isFavorite(id))
        Task { @MainActor in self.favoriteIds = ids }
    }
}
