import Foundation

@MainActor
class THFloorModel: ObservableObject {
    init(floor: THFloor, highlighted: Bool) {
        self.floor = floor
        self.highlighted = highlighted
    }
    
    @Published var floor: THFloor
    @Published var highlighted: Bool
    var collapse: Bool {
        floor.deleted || !floor.fold.isEmpty
    }
    var collapsedContent: String {
        floor.fold.isEmpty ? floor.content : floor.fold
    }
    
    func highlight() {
        highlighted = true
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            highlighted = false
        }
    }
    
    private func updateFloor(_ floor: THFloor) {
        let storey = self.floor.storey
        self.floor = floor
        self.floor.storey = storey
    }
    
    func delete() async throws {
        let deletedFloor = try await THRequests.deleteFloor(floorId: floor.id)
        updateFloor(deletedFloor)
    }
    
    func edit(_ content: String, specialTag: String = "", fold: String = "") async throws {
        let editedFloor = try await THRequests.modifyFloor(content: content, floorId: floor.id, specialTag: specialTag, fold: fold)
        updateFloor(editedFloor)
    }
    
    func like() async throws {
        let like = floor.liked ? 0 : 1
        let likedFloor = try await THRequests.like(floorId: floor.id, like: like)
        updateFloor(likedFloor)
    }
    
    func dislike() async throws {
        let dislike = floor.disliked ? 0 : -1
        let dislikedFloor = try await THRequests.like(floorId: floor.id, like: dislike)
        updateFloor(dislikedFloor)
    }
    
    func loadHistory() async throws -> [THHistory] {
        return try await THRequests.loadFloorHistory(floorId: floor.id)
    }
    
    func restore(_ id: Int, reason: String) async throws {
        let restoredFloor = try await THRequests.restoreFloor(floorId: floor.id, historyId: id, restoreReason: reason)
        updateFloor(restoredFloor)
    }
    
    func punish(_ reason: String, days: Int = 0) async throws {
        let deletedFloor = try await THRequests.deleteFloor(floorId: floor.id, reason: reason)
        updateFloor(deletedFloor)
        if days > 0 {
            try await THRequests.addPenalty(floor.id, days, reason: reason)
        }
    }
}
