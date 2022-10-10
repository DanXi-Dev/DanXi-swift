import Foundation
import SwiftUI

@MainActor
class HoleDetailViewModel: ObservableObject {
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
        case normal
        case fromId(holeId: Int)
        case targetFloor(targetFloorId: Int)
    }
    
    enum FilterOptions {
        case all
        case posterOnly
    }
    
    /// Initialize with hole info.
    init(hole: THHole) {
        self.hole = hole
        self.favorited = TreeholeDataModel.shared.user?.favorites.contains(hole.id) ?? false
        self.initOption = .normal
    }
    
    /// Initialize from hole ID, load hole info from networks.
    init(holeId: Int) {
        self.hole = nil
        self.favorited = TreeholeDataModel.shared.user?.favorites.contains(holeId) ?? false
        
        self.initOption = .fromId(holeId: holeId)
    }
    
    /// Initialize from floor ID, scroll to that floor.
    init(targetFloorId: Int) {
        self.hole = nil
        self.favorited = false
        
        self.initOption = .targetFloor(targetFloorId: targetFloorId)
    }
    
    /// Default initializer
    init() {
        self.hole = nil
        self.favorited = false
        self.initOption = .normal
    }
    
    func initialLoad() async {
        switch initOption {
        case .normal:
            break
            
        case .fromId(let holeId):
            do {
                hole = try await DXNetworks.shared.loadHoleById(holeId: holeId)
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
            
        case .targetFloor(let targetFloorId):
            do {
                let targetFloor = try await DXNetworks.shared.loadFloorById(floorId: targetFloorId)
                self.hole = try await DXNetworks.shared.loadHoleById(holeId: targetFloor.holeId)
                
                self.floors = try await DXNetworks.shared.loadAllFloors(holeId: targetFloor.holeId)
                try await Task.sleep(nanoseconds: UInt64(0.1 * Double(NSEC_PER_SEC))) // create a delay to prepare UI before scrolling
                scrollTarget = targetFloorId
            } catch NetworkError.notFound {
                errorTitle = "Floor Not Exist"
                errorInfo = String(format: NSLocalizedString("Floor ##%@ not exist", comment: ""), String(targetFloorId))
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
                    try await DXNetworks.shared.updateViews(holeId: hole.id)
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
                let newFloors = try await DXNetworks.shared.loadFloors(holeId: hole.id, startFloor: floors.count)
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
            self.floors = try await DXNetworks.shared.loadAllFloors(holeId: hole.id)
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
    
    func toggleFavorites() async {
        guard let hole = hole else {
            return
        }
        
        do {
            let favorites = try await DXNetworks.shared.toggleFavorites(holeId: hole.id, add: !favorited)
            TreeholeDataModel.shared.updateFavorites(favorites: favorites)
            favorited = favorites.contains(hole.id)
            haptic()
        } catch {
            errorTitle = "Toggle Favorite Failed"
            errorInfo = error.localizedDescription
            errorPresenting = true
        }
    }
    
    // prevent duplicate inserting ID.
    private func insertFloors(_ floors: [THFloor]) {
        let ids = self.floors.map(\.id)
        let filteredFloors = floors.filter { !ids.contains($0.id) }
        self.floors.append(contentsOf: filteredFloors)
    }
}
