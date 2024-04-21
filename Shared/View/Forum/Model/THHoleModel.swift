import SwiftUI
import Combine

@MainActor
class THHoleModel: ObservableObject {
    init(hole: THHole) {
        self.hole = hole
        self.floors = []
        self.isFavorite = THModel.shared.isFavorite(hole.id)
        self.subscribed = THModel.shared.isSubscribed(hole.id)
        self.initialScroll = nil
    }
    
    init(hole: THHole, floors: [THFloor], scrollTo: Int? = nil, loadMore: Bool = false) {
        self.hole = hole
        self.floors = []
        self.endReached = !loadMore
        self.subscribed = THModel.shared.isSubscribed(hole.id)
        self.isFavorite = THModel.shared.isFavorite(hole.id)
        self.initialScroll = scrollTo
        
        insertFloors(floors)
        if loadMore {
            Task(priority: .background) { // Prefetched data is incomplete, we need to send another request to get full data
                var refreshedPrefetchData = try await THRequests.loadFloors(holeId: hole.id, startFloor: 0)
                let replaceEnd = min(refreshedPrefetchData.count, self.floors.count) - 1
                guard replaceEnd >= 0 else { return }
                var storey = 1
                for i in 0..<refreshedPrefetchData.count {
                    refreshedPrefetchData[i].storey = storey
                    storey += 1
                }
                self.floors.replaceSubrange(0 ... replaceEnd, with: refreshedPrefetchData)
                floorChangedBroadcast.send(refreshedPrefetchData.map(\.id))
            }
        }
    }
    
    @Published var hole: THHole
    @Published var floors: [THFloor] {
        didSet {
            filterFloors()
        }
    }
    
    // MARK: - Floor Loading
    
    @Published var loading = false
    @Published var endReached = false
    @Published var imageURLs: [URL] = []
    
    func loadMoreFloors() async throws {
        guard !endReached else { return }
        let previousCount = filteredFloors.count
        while filteredFloors.count == previousCount && !endReached {
            let newFloors = try await THRequests.loadFloors(holeId: hole.id, startFloor: floors.count)
            insertFloors(newFloors)
            endReached = newFloors.isEmpty
        }
    }
    
    private func insertFloors(_ floors: [THFloor]) {
        let currentIds = self.floors.map(\.id)
        var insertFloors = floors.filter { !currentIds.contains($0.id) }
        
        var newImageURLs: [URL] = []
        
        var storey = (self.floors.last?.storey ?? 0) + 1
        for i in 0..<insertFloors.count {
            insertFloors[i].storey = storey
            storey += 1
            
            // parse content and extract remote image URLs
            let content = insertFloors[i].content
            guard let attributed = try? AttributedString(markdown: content) else { continue }
            for run in attributed.runs {
                if let imageURL = run.imageURL {
                    newImageURLs.append(imageURL)
                }
            }
        }
        self.floors += insertFloors
        self.imageURLs += newImageURLs
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
            filterFloors()
        }
    }
    
    @Published var filteredFloors: [THFloor] = []
    
    private func filterFloors() {
        switch filterOption {
        case .all:
            filteredFloors = self.floors
        case .posterOnly:
            let posterName = floors.first?.posterName ?? ""
            filteredFloors = self.floors.filter { floor in
                floor.posterName == posterName
            }
        case .user(let name):
            filteredFloors = self.floors.filter { $0.posterName == name }
        case .conversation(let starting):
            filteredFloors = traceConversation(starting)
        case .reply(let floorId):
            filteredFloors = findReply(floorId)
        }
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
            try? await self.loadAllFloors()
        }
    }
    
    // MARK: - Page Scrolling
    
    let initialScroll: Int?
    @Published var showLoadingAllDialog = false
    let scrollControl = PassthroughSubject<Int, Never>()
    
    func loadAllFloors() async throws {
        if endReached {
            if let lastFloorId = filteredFloors.last?.id {
                scrollControl.send(lastFloorId)
            }
            return
        }
        
        showLoadingAllDialog = true
        defer { showLoadingAllDialog = false }
        try await refreshAll()
        // sending value to publisher is moved to view
    }
    
    func refreshAll() async throws {
        let floors = try await THRequests.loadAllFloors(holeId: hole.id)
        insertFloors(floors)
        endReached = true
    }
    
    // MARK: - Subscription
    
    @Published var subscribed: Bool
    
    func toggleSubscribe() async throws {
        if subscribed {
            try await THModel.shared.deleteSubscription(hole.id)
        } else {
            try await THModel.shared.addSubscription(hole.id)
        }
        subscribed.toggle() // update subscription status
    }
    
    // MARK: - Favorite
    
    @Published var isFavorite: Bool
    
    func toggleFavorite() async throws {
        let favIds = try await THRequests.toggleFavorites(holeId: hole.id, add: !isFavorite)
        THModel.shared.favoriteIds = favIds
        self.isFavorite = THModel.shared.isFavorite(hole.id)
    }
    
    // MARK: - Floor Batch Delete (Admin)
    
    @Published var floorSelectable = false
    @Published var selectedFloor: Set<THFloor> = []
    let floorChangedBroadcast = PassthroughSubject<[Int], Never>()
    func batchDelete(_ floors: [THFloor], reason: String) async {
        let previousFloors = self.floors
        
        // send delete request to server
        let deletedFloors = await withTaskGroup(of: THFloor.self,
                                                returning: [THFloor].self,
                                                body: { taskGroup in
            for floor in floors {
                taskGroup.addTask {
                    do {
                        return try await THRequests.deleteFloor(floorId: floor.id, reason: reason)
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
        self.floors = newFloors
        // notify subviews
        floorChangedBroadcast.send(deletedFloors.map(\.id))
    }
    
    // MARK: - Hole Info Edit
    
    func modifyHole(_ info: THHoleInfo) async throws {
        self.hole = try await THRequests.modifyHole(info)
    }
    
    func deleteHole() async throws {
        try await THRequests.deleteHole(holeId: hole.id)
        self.hole.hidden = true
    }
}
