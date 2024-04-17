import SwiftUI
import Disk
import DanXiKit

class FavoriteStore: ObservableObject {
    static let shared = FavoriteStore()
    
    @Published var favoritedIds: [Int]
    
    init() {
        if let favoritedIds = try? Disk.retrieve("fduhole/favorites.json", from: .applicationSupport, as: [Int].self) {
            self.favoritedIds = favoritedIds
        } else {
            self.favoritedIds = []
        }
    }
    
    @MainActor
    private func set(favoritedIds: [Int]) {
        self.favoritedIds = favoritedIds
    }
    
    func isFavorite(_ id: Int) -> Bool {
        favoritedIds.contains(id)
    }
    
    func refreshFavoriteIds() async throws {
        let ids = try await ForumAPI.listFavoriteHoleIds()
        try Disk.save(ids, to: .applicationSupport, as: "fduhole/favorites.json")
        await set(favoritedIds: ids)
    }
    
    func toggleFavorite(_ id: Int) async throws {
        let ids = try await ForumAPI.toggleFavorite(holeId: id, add: !isFavorite(id))
        try Disk.save(ids, to: .applicationSupport, as: "fduhole/favorites.json")
        await set(favoritedIds: ids)
    }
    
    func clear() async {
        await set(favoritedIds: [])
        try? Disk.remove("fduhole/favorites.json", from: .applicationSupport)
    }
}
