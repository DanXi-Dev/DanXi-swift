import SwiftUI
import DanXiKit

class FloorModel: ObservableObject {
    @MainActor
    init(presentation: FloorPresentation) {
        let floor = presentation.floor
        self.floor = floor
        self.presentation = presentation
        self.liked = floor.liked
        self.disliked = floor.disliked
        self.likeCount = floor.like
        self.dislikeCount = floor.dislike
    }
    
    @Published var floor: Floor
    @Published var presentation: FloorPresentation
    var shouldFold: Bool {
        floor.deleted || !floor.fold.isEmpty
    }
    var foldContent: String {
        floor.fold.isEmpty ? floor.content : floor.fold
    }
    
    @Published var highlighted = false
    
    // FIXME: duplicate code
    func highlight() {
        Task { @MainActor in
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
    @Published var likeCount: Int
    @Published var disliked: Bool
    @Published var dislikeCount: Int
    
    @MainActor
    private func updateLiked(floor: Floor) {
        self.liked = floor.liked
        self.likeCount = floor.like
        self.disliked = floor.disliked
        self.dislikeCount = floor.dislike
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
    
    func foreverpunish(_ reason: String) async throws {
        let floor = try await ForumAPI.deleteFloor(id: floor.id, reason: reason)
        await updateFloor(floor)
        try await ForumAPI.foreverPenaltyForFloor(id: floor.id, reason: reason)
    }
}
