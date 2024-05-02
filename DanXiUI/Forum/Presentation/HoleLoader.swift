import SwiftUI
import ViewUtils
import DanXiKit

struct HoleLoader: Hashable {
    var floorId: Int?
    var holeId: Int?
    var hole: Hole?
    var floor: Floor?
    
    var loadFloors: Bool {
        (floorId != nil) || (floor != nil)
    }
    
    var scrollTo: Int? {
        if let floorId = floorId {
            return floorId
        }
        if let floor = floor {
            return floor.id
        }
        return nil
    }
    
    // MARK: - Initializer
    
    init() { }
    
    init(floorId: Int) {
        self.floorId = floorId
    }
    
    init(holeId: Int) {
        self.holeId = holeId
    }
    
    init(_ hole: Hole) {
        self.hole = hole
    }
    
    init(_ floor: Floor) {
        self.floor = floor
    }
    
    // MARK: - Loaders
    
    func loadHoleId() async throws -> Int {
        if let holeId = holeId {
            return holeId
        }
        
        if let hole = hole {
            return hole.id
        }
        
        if let floor = floor {
            return floor.holeId
        }
        
        return try await ForumAPI.getFloor(id: floorId!).holeId
    }
    
    func loadHole(_ holeId: Int) async throws -> Hole {
        if let hole = hole {
            return hole
        }
        
        return try await ForumAPI.getHole(id: holeId)
    }
    
    func load() async throws -> HoleModel {
        let holeId = try await loadHoleId()
        let hole = try await loadHole(holeId)
        
        if loadFloors {
            let floors = try await ForumAPI.listAllFloors(holeId: holeId)
            return await HoleModel(hole: hole, floors: floors, scrollTo: scrollTo)
        } else {
            return await HoleModel(hole: hole)
        }
    }
}

struct HoleLoaderPage: View {
    let loader: HoleLoader
    
    var body: some View {
        AsyncContentView { _ in
            return try await loader.load()
        } content: { model in
            HolePage(model)
        }
    }
}
