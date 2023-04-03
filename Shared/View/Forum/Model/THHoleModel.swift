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
        self.initialScroll = scrollTo
        
        insertFloors(floors)
    }
    
    @Published var hole: THHole
    @Published var floors: [THFloor] {
        didSet {
            cacheUpdated = false
        }
    }
    
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
        var storey = (self.floors.last?.storey ?? 0) + 1
        for i in 0..<insertFloors.count {
            insertFloors[i].storey = storey
            storey += 1
        }
        withAnimation {
            self.floors.append(contentsOf: insertFloors)
        }
    }
    
    // MARK: - Floor Filtering
    
    enum FilterOptions: Hashable {
        case all
        case posterOnly
        case user(name: String)
        case conversation(starting: Int)
        case reply(floorId: Int)
    }
    
    @Published var filterOption = FilterOptions.all {
        didSet {
            cacheUpdated = false
        }
    }
    
    private var cacheUpdated = false
    private var cachedFloors: [THFloor] = [] // cache calculated filtered floors result to improve performance
    
    var filteredFloors: [THFloor] {
        if cacheUpdated { return cachedFloors }
        
        switch filterOption {
        case .all:
            cachedFloors = self.floors
        case .posterOnly:
            let posterName = floors.first?.posterName ?? ""
            cachedFloors = self.floors.filter { floor in
                floor.posterName == posterName
            }
        case .user(let name):
            cachedFloors = self.floors.filter { $0.posterName == name }
        case .conversation(let starting):
            cachedFloors = traceConversation(starting)
        case .reply(let floorId):
            cachedFloors = findReply(floorId)
        }
        
        cacheUpdated = true
        return cachedFloors
    }
    
    
    private func traceConversation(_ startId: Int) -> [THFloor] {
        var forwardId: Int? = startId
        var backwardId: Int? = startId
        var conversation: [THFloor] = []
        
        // trace forward
        while let floorId = forwardId {
            if let floor = floors.first(where: { $0.id == floorId }) {
                conversation.append(floor)
                forwardId = floor.firstMention()
            } else { // no matching floor is found, end searching
                break
            }
        }
        
        conversation = conversation.reversed()
        
        // trace backward
        while true {
            if let floor = floors.first(where: { $0.firstMention() == backwardId }) {
                conversation.append(floor)
                backwardId = floor.id
            } else { // no match found, end searching
                break
            }
        }
        
        return conversation
    }
    
    private func findReply(_ floorId: Int) -> [THFloor] {
        print("finding reply")
        var replies = floors.filter { floor in
            floor.firstMention() == floorId
        }
        if let baseFloor = floors.filter({ $0.id == floorId }).first {
            replies.insert(baseFloor, at: 0)
        }
        return replies
    }
    
    var showBottomBar: Bool {
        switch filterOption {
        case .user(_):
            return true
        case .conversation(_):
            return true
        case .reply(_):
            return true
        default:
            return false
        }
    }
    
    // MARK: - Reply
    
    func reply(_ content: String) async throws {
        _ = try await THRequests.createFloor(content: content, holeId: hole.id)
        self.endReached = false
        Task {
            await self.loadAllFloors()
        }
    }
    
    // MARK: - Page Scrolling
    
    @Published var initialScroll: Int?
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
            scrollTarget = hole.lastFloor.id
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
    
    // MARK: - Floor Batch Delete (Admin)
    
    @Published var selectedFloor: Set<THFloor> = []
    @Published var deleteReason = ""
    
    func batchDelete() async {
        let floors = Array(selectedFloor)
        let previousFloors = self.floors
        
        // send delete request to server
        let deletedFloors = await withTaskGroup(of: THFloor.self,
                                                returning: [THFloor].self,
                                                body: { taskGroup in
            for floor in floors {
                taskGroup.addTask {
                    do {
                        return try await THRequests.deleteFloor(floorId: floor.id, reason: self.deleteReason)
                    } catch {
                        return floor
                    }
                }
            }
            
            var deletedFloors: [THFloor] = []
            for await floor in taskGroup {
                deletedFloors.append(floor)
            }
            return deletedFloors
        })
        
        // replace deleted floors with server-returned results
        var newFloors: [THFloor] = []
        for floor in previousFloors {
            var newFloor: THFloor? = nil
            for deletedFloor in deletedFloors {
                if deletedFloor.id == floor.id {
                    newFloor = deletedFloor
                    newFloor?.storey = floor.storey
                    break
                }
            }
            
            if let newFloor = newFloor { // find matched deleted floor
                newFloors.append(newFloor)
            } else { // nothing matched, use original
                newFloors.append(floor)
            }
        }
        
        // submit UI change
        Task { @MainActor in
            self.floors = newFloors
        }
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
