import Foundation
import SwiftUI

class THStore: ObservableObject {
    static var shared = THStore()
    
    @Published var divisions: [THDivision] = []
    @Published var tags: [THTag] = []
    @Published var favorites: [Int] = []
    @Published var initialized = false
    @Published var path = NavigationPath()
    
    // MARK: General Interfaces
    
    func loadAll() async throws {
        guard !initialized else { return }
        
        let divisions = try await THRequests.loadDivisions()
        let favorites = try await THRequests.loadFavoritesIds()
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
        let favorites: [Int] = try await THRequests.toggleFavorites(holeId: holeId, add: add)
        Task { @MainActor in
            self.favorites = favorites
        }
    }
    
    func modifyFavorites(_ holeIds: [Int]) async throws {
        let favorites: [Int] = try await THRequests.modifyFavorites(holeIds: holeIds)
        Task { @MainActor in
            self.favorites = favorites
        }
    }
    
    func reloadFavorites() async throws {
        let favorites: [Int] = try await THRequests.loadFavoritesIds()
        Task { @MainActor in
            self.favorites = favorites
        }
    }
    
    // MARK: Tags Cache Control
    
    private let defaults = UserDefaults.standard
    
    private func tagsCacheExpired() -> Bool {
        do {
            if let data = defaults.data(forKey: "th-tags-last-fetch") {
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
        Task { @MainActor in
            self.tags = try FileStore.caches.loadDecoded("th-tags.data")
        }
    }
    
    private func updateTagsCache() async throws {
        let tags = try await THRequests.loadTags()
        try FileStore.caches.saveEncoded(tags, filename: "th-tags.data")
        defaults.setValue(try JSONEncoder().encode(Date()), forKey: "th-tags-last-fetch")
        
        Task { @MainActor in
            self.tags = tags
        }
    }
    
    private func clearTags() {
        self.tags = []
        defaults.removeObject(forKey: "th-tags-last-fetch")
        do {
            try FileStore.caches.remove("th-tags.data")
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