import Foundation

class TreeholeStore: ObservableObject {
    static var shared = TreeholeStore()
    
    @Published var divisions: [THDivision] = []
    @Published var tags: [THTag] = []
    @Published var favorites: [Int] = []
    @Published var initialized = false
    
    // MARK: General Interfaces
    
    func loadAll() async throws {
        guard !initialized else { return }
        
        let divisions = try await TreeholeRequests.loadDivisions()
        let favorites = try await TreeholeRequests.loadFavoritesIds()
        try await loadTags()
        
        Task { @MainActor in
            self.divisions = divisions
            self.favorites = favorites
            initialized = true
        }
    }
    
    func clear() {
        initialized = false
        
        self.divisions = []
        self.favorites = []
        clearTags()
    }
    
    // MARK: Favorites Editing
    
    func isFavorite(_ holeId: Int) -> Bool {
        return favorites.contains(holeId)
    }
    
    func toggleFavorites(_ holeId: Int, add: Bool) async throws {
        self.favorites = try await TreeholeRequests.toggleFavorites(holeId: holeId, add: add)
    }
    
    func modifyFavorites(_ holeIds: [Int]) async throws {
        self.favorites = try await TreeholeRequests.modifyFavorites(holeIds: holeIds)
    }
    
    func reloadFavorites() async throws {
        self.favorites = try await TreeholeRequests.loadFavoritesIds()
    }
    
    // MARK: Tags Cache Control
    
    private let defaults = UserDefaults(suiteName: "group.io.github.kavinzhao.fdutools")
    private let tagsCacheUrl = try! FileManager.default.url(for: .cachesDirectory,
                                                           in: .userDomainMask,
                                                           appropriateFor: nil,
                                                           create: false)
                                    .appendingPathComponent("th-tags.data")
    
    private func tagsCacheExpired() -> Bool {
        do {
            if let data = defaults?.data(forKey: "th-tags-last-fetch") {
                let lastFetchDate = try JSONDecoder().decode(Date.self, from: data)
                let interval = Date().timeIntervalSince(lastFetchDate)
                if interval < 60.0 * 60.0 * 24 {
                    return false
                }
            }
            return true
        } catch {
            return true
        }
    }
    
    private func loadTagsCache() throws {
        let file = try FileHandle(forReadingFrom: tagsCacheUrl)
        let tags = try JSONDecoder().decode([THTag].self, from: file.availableData)
        Task { @MainActor in
            self.tags = tags
        }
    }
    
    private func updateTagsCache() async throws {
        let tags = try await TreeholeRequests.loadTags()
        try saveData(tags, filename: "th-tags.data")
        defaults?.setValue(try JSONEncoder().encode(Date()), forKey: "th-tags-last-fetch")
        
        Task { @MainActor in
            self.tags = tags
        }
    }
    
    private func clearTags() {
        self.tags = []
        defaults?.removeObject(forKey: "th-tags-last-fetch")
        do {
            try FileManager.default.removeItem(at: tagsCacheUrl)
        } catch { }
    }
    
    func loadTags() async throws {
        if tagsCacheExpired() {
            try await updateTagsCache()
            return
        }
        
        do {
            try loadTagsCache()
        } catch {
            try await updateTagsCache()
            return
        }
    }
}
