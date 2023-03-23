import Foundation

/// Load `THHole` from a varienty of load options.
struct THHoleLoader {
    var floorId: Int?
    var holeId: Int?
    var hole: THHole?
    var floor: THFloor?
    
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
    
    init(_ hole: THHole) {
        self.hole = hole
    }
    
    init(_ floor: THFloor) {
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
        
        return try await THRequests.loadFloorById(floorId: floorId!).holeId
    }
    
    func loadHole(_ holeId: Int) async throws -> THHole {
        if let hole = hole {
            return hole
        }
        
        return try await THRequests.loadHoleById(holeId: holeId)
    }
    
    func load() async throws -> THHoleModel {
        let holeId = try await loadHoleId()
        let hole = try await loadHole(holeId)
        
        if loadFloors {
            let floors = try await THRequests.loadAllFloors(holeId: holeId)
            return await THHoleModel(hole: hole, floors: floors, scrollTo: scrollTo)
        } else {
            return await THHoleModel(hole: hole)
        }
    }
}
