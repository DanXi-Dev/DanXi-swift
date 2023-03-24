import Foundation

@MainActor
class THFloorModel: ObservableObject {
    init(floor: THFloor, context: THHoleModel) {
        self.floor = floor
        self.context = context
    }
    
    @Published var floor: THFloor
    var context: THHoleModel
    var isPoster: Bool {
        floor.posterName == context.floors.first?.posterName
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
    
    func edit(_ content: String, specialTag: String = "") async throws {
        let editedFloor = try await THRequests.modifyFloor(content: content, floorId: floor.id, specialTag: specialTag)
        updateFloor(editedFloor)
    }
    
    func like() async throws {
        let like = floor.liked ? 0 : 1
        let likedFloor = try await THRequests.like(floorId: floor.id, like: like)
        updateFloor(likedFloor)
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
