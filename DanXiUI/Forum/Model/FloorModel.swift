import SwiftUI
import DanXiKit

class FloorModel: ObservableObject {
    init(floor: Floor) {
        self.floor = floor
        self.liked = floor.liked
        self.disliked = floor.disliked
    }
    
    @Published var floor: Floor
    var shouldFold: Bool {
        floor.deleted || floor.fold.isEmpty
    }
    var foldContent: String {
        floor.fold.isEmpty ? floor.content : floor.fold
    }
    
    @Published var highlighted = false
    
    func highlight() {
        Task {
            withAnimation {
                highlighted = true
            }
            try await Task.sleep(for: .seconds(0.1))
            withAnimation {
                highlighted = false
            }
            try await Task.sleep(for: .seconds(0.2))
            withAnimation {
                highlighted = true
            }
            try await Task.sleep(for: .seconds(0.1))
            withAnimation {
                highlighted = false
            }
        }
    }
    
    @Published var liked: Bool
    @Published var disliked: Bool
    
    @MainActor
    private func updateLiked(floor: Floor) {
        self.liked = floor.liked
        self.disliked = floor.disliked
    }
    
    func like() async throws {
        let like = liked ? 0 : 1
        let floor = try await ForumAPI.likeFloor(id: floor.id, like: like)
        await updateLiked(floor: floor)
    }
    
    func dislike() async throws {
        let dislike = disliked ? 0 : -1
        let floor = try await ForumAPI.likeFloor(id: floor.id, like: dislike)
        await updateLiked(floor: floor)
    }
    
    @MainActor
    private func updateFloor(_ floor: Floor) {
        self.floor = floor
    }
    
    func delete() async throws {
        let floor = try await ForumAPI.deleteFloor(id: floor.id)
        await updateFloor(floor)
    }
    
    func edit(content: String, specialTag: String = "", fold: String = "") async throws {
        let floor = try await ForumAPI.modifyFloor(id: floor.id, content: content, specialTag: specialTag, fold: fold)
        await updateFloor(floor)
    }
    
    func loadHistory() async throws -> [FloorHistory] {
        return try await ForumAPI.listFloorHistory(id: floor.id)
    }
    
    func restore(id: Int, reason: String) async throws {
        let floor = try await ForumAPI.restoreFloor(id: floor.id, historyId: id, reason: reason)
        await updateFloor(floor)
    }
    
    func punish(_ reason: String, days: Int = 0) async throws {
        let floor = try await ForumAPI.deleteFloor(id: floor.id, reason: reason)
        await updateFloor(floor)
        if days > 0 {
            try await ForumAPI.penaltyForFloor(id: floor.id, reason: reason, days: days)
        }
    }
}
