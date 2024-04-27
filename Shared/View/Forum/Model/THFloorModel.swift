import Foundation
import SwiftUI

@MainActor
class THFloorModel: ObservableObject {
    init(floor: THFloor) {
        self.floor = floor
    }
    
    @Published var floor: THFloor
    @Published var highlighted = false
    var collapse: Bool {
        floor.collapse
    }
    var collapsedContent: String {
        floor.fold.isEmpty ? floor.content : floor.fold
    }
    
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
        var likedFloor = try await THRequests.like(floorId: floor.id, like: like)
        likedFloor.mention = floor.mention // the server response will not include mention for performance reason
        updateFloor(likedFloor)
    }
    
    func dislike() async throws {
        let dislike = floor.disliked ? 0 : -1
        var dislikedFloor = try await THRequests.like(floorId: floor.id, like: dislike)
        dislikedFloor.mention = floor.mention // the server response will not include mention for performance reason
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
