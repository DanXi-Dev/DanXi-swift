import Foundation
import SwiftUI

@MainActor
class HoleDetailViewModel: ObservableObject {
    @Published var hole: THHole?
    @Published var favorited: Bool
    
    @Published var floors: [THFloor] = []
    @Published var endReached = false
    
    @Published var prefetchReloaded = true
    @Published var prefetchedCount = 0
    
    @Published var filterOption: FilterOptions = .all
    var filteredFloors: [THFloor] {
        let poster = hole?.firstFloor.posterName ?? ""
        
        return floors.filter { floor in
            (filterOption == .all || floor.posterName == poster)
        }
    }
    
    @Published var errorPresenting = false
    @Published var errorInfo = ErrorInfo()
    
    @Published var listLoading = true
    @Published var listError = ErrorInfo()
    
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
    
    /// Initialize with hole info
    init(hole: THHole) {
        self.hole = hole
        self.favorited = TreeholeDataModel.shared.user?.favorites.contains(hole.id) ?? false
        self.floors = hole.floors
        self.prefetchReloaded = false
        self.prefetchedCount = hole.floors.count
        self.initOption = .normal
    }
    
    /// Initialize from hole ID, load hole info from networkr
    init(holeId: Int) {
        self.hole = nil
        self.favorited = TreeholeDataModel.shared.user?.favorites.contains(holeId) ?? false
        
        self.initOption = .fromId(holeId: holeId)
    }
    
    /// Initialize from floor ID, scroll to that floor
    init(targetFloorId: Int) {
        self.hole = nil
        self.favorited = false
        
        self.initOption = .targetFloor(targetFloorId: targetFloorId)
    }
    
    func initialLoad(proxy: ScrollViewProxy) async {
        switch initOption {
        case .normal:
            if !prefetchReloaded {
                do {
                    guard let hole = hole else {
                        break
                    }
                    
                    let newFloors = try await NetworkRequests.shared.loadFloors(holeId: hole.id, startFloor: 0, length: prefetchedCount)
                    floors = newFloors
                    floors.replaceSubrange(0..<prefetchedCount, with: newFloors) // FIXME: won't take effect on UI
                    prefetchReloaded = true // prevent duplicate loading
                } catch {
                    print("DANXI-DEBUG: prefetch reload failed")
                }
            }

            
        case .fromId(let holeId):
            do {
                hole = try await NetworkRequests.shared.loadHoleById(holeId: holeId)
            } catch NetworkError.notFound {
                errorInfo = ErrorInfo(title: "Treehole Not Exist", description: "Treehole #\(String(holeId)) not exist")
                errorPresenting = true
                return
            } catch let error as NetworkError {
                errorInfo = error.localizedErrorDescription
                errorPresenting = true
                return
            } catch {
                print("DANXI-DEBUG: load hole info failed")
            }
            
        case .targetFloor(let targetFloorId):
            do {
                let targetFloor = try await NetworkRequests.shared.loadFloorById(floorId: targetFloorId)
                self.hole = try await NetworkRequests.shared.loadHoleById(holeId: targetFloor.holeId)
                
                var newFloors: [THFloor] = []
                var floors: [THFloor] = []
                repeat {
                    newFloors = try await NetworkRequests.shared.loadFloors(holeId: targetFloor.holeId, startFloor: floors.count)
                    floors.append(contentsOf: newFloors)
                    if newFloors.contains(targetFloor) {
                        break
                    }
                } while !newFloors.isEmpty
                self.floors = floors // insert to view at last, preventing automatic refresh causing URLSession to cancel
            } catch NetworkError.notFound {
                errorInfo = ErrorInfo(title: "Floor Not Exist", description: "Floor ##\(String(targetFloorId)) not exist")
                errorPresenting = true
                return
            } catch let error as NetworkError {
                errorInfo = error.localizedErrorDescription
                errorPresenting = true
                return
            } catch {
                print("DANXI-DEBUG: load to target floor failed")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // hack to give a time redraw
                withAnimation {
                    proxy.scrollTo(targetFloorId, anchor: .top)
                }
            }
        }
        
        if floors.isEmpty {
            await loadMoreFloors()
        }
        
        Task { // update viewing count
            if let hole = hole {
                do {
                    try await NetworkRequests.shared.updateViews(holeId: hole.id)
                } catch {
                    print("DANXI-DEBUG: update viewing count failed")
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
            if !prefetchReloaded { // The prefetched floors lacks `isMe` property, need to be reloaded
                let newFloors = try await NetworkRequests.shared.loadFloors(holeId: hole.id, startFloor: 0, length: prefetchedCount)
                floors = newFloors
                floors.replaceSubrange(0..<prefetchedCount, with: newFloors) // FIXME: won't take effect on UI
                prefetchReloaded = true // prevent duplicate loading
            }
            
            let previousCount = filteredFloors.count
            while filteredFloors.count == previousCount && !endReached {
                let newFloors = try await NetworkRequests.shared.loadFloors(holeId: hole.id, startFloor: floors.count)
                floors.append(contentsOf: newFloors)
                endReached = newFloors.isEmpty
            }
        } catch NetworkError.ignore {
            // cancelled, ignore
        } catch let error as NetworkError {
            listError = error.localizedErrorDescription
        } catch {
            listError = ErrorInfo(title: "Unknown Error",
                                  description: "Error description: \(error.localizedDescription)")
        }
    }
    
    func loadToBottom() async {
        guard let hole = hole else {
            return
        }
        
        do {
            var newFloors: [THFloor] = []
            var floors: [THFloor] = self.floors
            
            repeat {
                newFloors = try await NetworkRequests.shared.loadFloors(holeId: hole.id, startFloor: floors.count)
                floors.append(contentsOf: newFloors)
            } while !newFloors.isEmpty
            
            self.floors = floors
        } catch {
            print("DANXI-DEBUG: load to bottom failed")
        }
    }
    
    func toggleFavorites() async {
        guard let hole = hole else {
            return
        }
        
        do {
            let favorites = try await NetworkRequests.shared.toggleFavorites(holeId: hole.id, add: !favorited)
            TreeholeDataModel.shared.updateFavorites(favorites: favorites)
            favorited = favorites.contains(hole.id)
            haptic()
        } catch {
            print("DANXI-DEBUG: toggle favorite failed")
        }
    }
    
    func fetchFloorFromID(_ floorId: Int) -> THFloor? {
        for floor in floors {
            if floor.id == floorId {
                return floor
            }
        }
        return nil
    }
}
