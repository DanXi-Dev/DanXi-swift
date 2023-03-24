import Foundation
import SwiftUI

@MainActor
class THHoleModel: ObservableObject {
    init(hole: THHole) {
        self.hole = hole
        self.floors = []
        self.isFavorite = DXModel.shared.isFavorite(hole.id)
        self.scrollTarget = -1
    }
    
    init(hole: THHole, floors: [THFloor], scrollTo: Int? = nil) {
        self.hole = hole
        self.floors = []
        self.endReached = true
        self.isFavorite = DXModel.shared.isFavorite(hole.id)
        self.scrollTarget = scrollTo ?? -1
        
        insertFloors(floors)
    }
    
    @Published var hole: THHole
    @Published var floors: [THFloor]
    
    // MARK: - Floor Loading
    
    @Published var loading = false
    @Published var loadingError: Error?
    @Published var endReached = false
    
    func loadMoreFloors() async {
        guard !endReached else { return }
        
        loading = true
        defer { loading = false }
        
        do {
            let previousCount = filteredFloors.count
            while filteredFloors.count == previousCount && !endReached {
                let newFloors = try await THRequests.loadFloors(holeId: hole.id, startFloor: floors.count)
                insertFloors(newFloors)
                endReached = newFloors.isEmpty
            }
        } catch {
            loadingError = error
        }
    }
    
    private func insertFloors(_ floors: [THFloor]) {
        let currentIds = self.floors.map(\.id)
        var insertFloors = floors.filter { !currentIds.contains($0.id) }
        var storey = (floors.first?.storey ?? 0) + 1
        for i in 0..<insertFloors.count {
            insertFloors[i].storey = storey
            storey += 1
        }
        
        self.floors.append(contentsOf: insertFloors)
    }
    
    // MARK: - Floor Filtering
    
    enum FilterOptions: Hashable {
        case all
        case posterOnly
    }
    
    @Published var filterOption = FilterOptions.all
    var filteredFloors: [THFloor] {
        switch filterOption {
        case .all:
            return self.floors
        case .posterOnly:
            let posterName = floors.first?.posterName ?? ""
            return self.floors.filter { floor in
                floor.posterName == posterName
            }
        }
    }
    var displayBottomBar: Bool {
        false
    }
    
    // MARK: - Reply
    
    func reply(_ content: String) async throws {
        _ = try await THRequests.createFloor(content: content, holeId: hole.id)
        Task {
            await self.loadAllFloors()
        }
    }
    
    // MARK: - Page Scrolling
    
    @Published var scrollTarget: Int
    @Published var loadingAll = false
    
    func loadAllFloors() async {
        if endReached {
            withAnimation {
                scrollTarget = hole.lastFloor.id
            }
            return
        }
        
        do {
            loadingAll = true
            defer { loadingAll = false }
            let floors = try await THRequests.loadAllFloors(holeId: hole.id)
            insertFloors(floors)
            endReached = true
            withAnimation {
                scrollTarget = hole.lastFloor.id
            }
        } catch {
            loadingError = error
        }
    }
    
    // MARK: - Favorite
    
    @Published var isFavorite: Bool
    
    func toggleFavorite() async throws {
        let favIds = try await THRequests.toggleFavorites(holeId: hole.id, add: !isFavorite)
        DXModel.shared.favoriteIds = favIds
        self.isFavorite = DXModel.shared.isFavorite(hole.id)
    }
    
    // MARK: - Hole Info Edit
    
    func modifyHole(_ info: THHoleInfo) async throws {
        self.hole = try await THRequests.modifyHole(info)
    }
    
    func deleteHole() async throws {
        try await THRequests.deleteHole(holeId: hole.id)
        self.hole.hidden = true
    }
    
    func lockHole() async throws {
        // TODO
    }
    
    func deleteSelection() async throws {
        // TODO
    }
}