import Foundation
import SwiftUI

@MainActor
class HoleDetailViewModel: ObservableObject {
    let store = TreeholeStore.shared
    @Published var hole: THHole?
    @Published var favorited: Bool
    
    @Published var floors: [THFloor] = []
    @Published var endReached = false
    
    @Published var filterOption: FilterOptions = .all
    var filteredFloors: [THFloor] {
        let poster = hole?.firstFloor.posterName ?? ""
        
        return floors.filter { floor in
            (filterOption == .all || floor.posterName == poster)
        }
    }
    
    @Published var errorPresenting = false
    @Published var errorTitle: LocalizedStringKey = "Error"
    @Published var errorInfo = ""
    
    @Published var listLoading = true
    @Published var listError = ""
    
    @Published var scrollTarget: Int = -1
    @Published var loadingToBottom = false
    
    let initOption: InitOptions
    
    enum InitOptions {
        case fromHole(floorId: Int?)
        case fromHoleId(holeId: Int, floorId: Int?)
        case fromFloorId(floorId: Int)
    }
    
    enum FilterOptions {
        case all
        case posterOnly
    }
    
    /// Initialize with hole info.
    init(hole: THHole, floorId: Int?) {
        self.hole = hole
        self.favorited = store.isFavorite(hole.id)
        self.initOption = .fromHole(floorId: floorId)
    }
    
    /// Initialize from hole ID, load hole info from networks.
    init(holeId: Int, floorId: Int?) {
        self.hole = nil
        self.favorited = store.isFavorite(holeId)
        self.initOption = .fromHoleId(holeId: holeId, floorId: floorId)
    }
    
    /// Initialize from floor ID, scroll to that floor.
    init(floorId: Int) {
        self.hole = nil
        self.favorited = false // should be re-calculated after hole ID is loaded
        self.initOption = .fromFloorId(floorId: floorId)
    }
    
    /// Default initializer
    init() {
        self.hole = nil
        self.favorited = false
        self.initOption = .fromHole(floorId: nil)
    }
    
    func initialLoad() async {
        switch initOption {
        case .fromHole(floorId: let floorId):
            scrollTarget = floorId ?? -1
            
        case .fromHoleId(let holeId, let floorId):
            do {
                hole = try await TreeholeRequests.loadHoleById(holeId: holeId)
                scrollTarget = floorId ?? -1
            } catch NetworkError.notFound {
                errorTitle = "Treehole Not Exist"
                errorInfo = String(format: NSLocalizedString("Treehole #%@ not exist", comment: ""), String(holeId))
                errorPresenting = true
                return
            } catch {
                errorTitle = "Error"
                errorInfo = error.localizedDescription
                errorPresenting = true
            }
            
        case .fromFloorId(let floorId):
            do {
                let targetFloor = try await TreeholeRequests.loadFloorById(floorId: floorId)
                let hole = try await TreeholeRequests.loadHoleById(holeId: targetFloor.holeId)
                self.hole = hole
                self.favorited = store.isFavorite(hole.id)
                
                self.floors = try await TreeholeRequests.loadAllFloors(holeId: targetFloor.holeId)
                try await Task.sleep(nanoseconds: UInt64(0.1 * Double(NSEC_PER_SEC))) // create a delay to prepare UI before scrolling
                scrollTarget = floorId
            } catch NetworkError.notFound {
                errorTitle = "Floor Not Exist"
                errorInfo = String(format: NSLocalizedString("Floor ##%@ not exist", comment: ""), String(floorId))
                errorPresenting = true
                return
            } catch {
                errorTitle = "Error"
                errorInfo = error.localizedDescription
                errorPresenting = true
            }
        }
        
        if floors.isEmpty {
            await loadMoreFloors()
        }
        
        Task { // update viewing count
            if let hole = hole {
                do {
                    try await TreeholeRequests.updateViews(holeId: hole.id)
                }
            }
        }
    }
    
    
    func loadMoreFloors() async {
        guard let hole = hole else {
            return
        }
        
        listLoading = true
        defer { listLoading = false }
        
        do {
            let previousCount = filteredFloors.count
            while filteredFloors.count == previousCount && !endReached {
                let newFloors = try await TreeholeRequests.loadFloors(holeId: hole.id, startFloor: floors.count)
                insertFloors(newFloors)
                endReached = newFloors.isEmpty
            }
        } catch {
            listError = error.localizedDescription
        }
    }
    
    func loadToBottom() async {
        guard let hole = hole else {
            return
        }
        
        if endReached {
            withAnimation {
                scrollTarget = hole.lastFloor.id
            }
            return
        }
        
        do {
            loadingToBottom = true
            defer { loadingToBottom = false }
            self.floors = try await TreeholeRequests.loadAllFloors(holeId: hole.id)
            endReached = true
            withAnimation {
                scrollTarget = hole.lastFloor.id
            }
        } catch {
            errorTitle = "Error"
            errorInfo = error.localizedDescription
            errorPresenting = true
        }
    }
    
    func toggleFavorites() {
        guard let hole = hole else {
            return
        }
        
        Task {
            do {
                try await store.toggleFavorites(hole.id, add: !favorited)
                favorited = store.favorites.contains(hole.id)
                haptic()
            } catch {
                errorTitle = "Toggle Favorite Failed"
                errorInfo = error.localizedDescription
                errorPresenting = true
            }
        }
    }
    
    // prevent duplicate inserting ID.
    private func insertFloors(_ floors: [THFloor]) {
        let ids = self.floors.map(\.id)
        let filteredFloors = floors.filter { !ids.contains($0.id) }
        self.floors.append(contentsOf: filteredFloors)
    }
}
