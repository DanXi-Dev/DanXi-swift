import Combine
import SwiftUI
import DanXiKit

class HoleModel: ObservableObject {
    init(hole: Hole) {
        self.hole = hole
        self.floors = []
        self.initialScroll = nil
        self.isFavorite = FavoriteStore.shared.isFavorite(hole.id)
        self.subscribed = SubscriptionStore.shared.isSubscribed(hole.id)
    }
    
    init(hole: Hole, floors: [Floor], scrollTo: Int? = nil, refreshPrefetch: Bool = false) {
        self.hole = hole
        var floorPresentations: [FloorPresentation] = []
        for (index, floor) in floors.enumerated() {
            let floorPresentation = FloorPresentation(floor: floor, storey: index + 1, floors: floors)
            floorPresentations.append(floorPresentation)
        }
        self.floors = floorPresentations
        self.initialScroll = scrollTo
        self.isFavorite = FavoriteStore.shared.isFavorite(hole.id)
        self.subscribed = SubscriptionStore.shared.isSubscribed(hole.id)
    }
    
    @Published var hole: Hole
    @Published var floors: [FloorPresentation] {
        didSet {
             filterFloors()
        }
    }
    
    var imageURLs: [URL] {
        floors.reduce([]) { urls, floor in
            urls + floor.imageURLs
        }
    }
    
    @MainActor
    func updateFloor(floor: Floor) {
        guard let idx = floors.firstIndex(where: { $0.floor.id == floor.id }) else { return }
        let storey = floors[idx].storey
        let context = floors.map(\.floor)
        let presentation = FloorPresentation(floor: floor, storey: storey, floors: context)
        floors[idx] = presentation
    }
    
    // MARK: - Floor Loading
    
    @Published var loading = false
    @Published var loadingAll = false
    @Published var endReached = false
    
    @MainActor
    func insertFloors(floors: [FloorPresentation]) {
        let ids = self.floors.map(\.floor.id)
        self.floors += floors.filter { !ids.contains($0.floor.id) }
    }
    
    func loadMoreFloors() async throws {
        if endReached { return }
        
        let previousCount = filteredFloors.count
        while previousCount == filteredFloors.count {
            let newFloors = try await ForumAPI.listFloorsInHole(holeId: hole.id, startFloor: floors.count)
            if newFloors.isEmpty {
                endReached = true
                return
            }
            let contextFloors = floors.map { $0.floor } + newFloors
            let baseStory = self.floors.count + 1
            var newPresentations: [FloorPresentation] = []
            for (index, floor) in newFloors.enumerated() {
                let presentation = FloorPresentation(floor: floor, storey: baseStory + index, floors: contextFloors)
                newPresentations.append(presentation)
            }
            await insertFloors(floors: newPresentations)
        }
    }
    
    func refreshPrefetched(count: Int) async throws {
        let newFloors = try await ForumAPI.listFloorsInHole(holeId: hole.id, startFloor: 0, size: count)
        var newPresentations: [FloorPresentation] = []
        for (index, floor) in newFloors.enumerated() {
            let presentation = FloorPresentation(floor: floor, storey: index + 1, floors: newFloors)
            newPresentations.append(presentation)
        }
        let refreshedPrefetch = newPresentations // thread-safe copy
        Task { @MainActor in
            floors.replaceSubrange(0..<count, with: refreshedPrefetch)
        }
    }
    
    func loadAllFloors() async throws {
        loadingAll = true
        defer { loadingAll = false }
        let floors = try await ForumAPI.listAllFloors(holeId: hole.id)
        var presentations: [FloorPresentation] = []
        for (index, floor) in floors.enumerated() {
            let presentation = FloorPresentation(floor: floor, storey: index + 1, floors: floors)
            presentations.append(presentation)
        }
        await insertFloors(floors: presentations)
    }
    
    // MARK: - Floor Filtering
    
    enum FilterOptions: Hashable {
        case all
        case posterOnly
        case user(String)
        case conversation(Int)
        case reply(Int)
    }
    
    @Published var filterOption = FilterOptions.all {
        didSet {
            filterFloors()
        }
    }
    
    @Published var filteredFloors: [FloorPresentation] = []
    
    private func filterFloors() {
        switch filterOption {
        case .all:
            filteredFloors = floors
        case .posterOnly:
            let poster = floors.first?.floor.anonyname
            filteredFloors = floors.filter { $0.floor.anonyname == poster }
        case .user(let name):
            filteredFloors = floors.filter { $0.floor.anonyname == name }
        case .conversation(let starting):
            filteredFloors = traceConversation(startId: starting)
        case .reply(let floorId):
            filteredFloors = floors.filter { $0.replyTo == floorId }
        }
    }
    
    private func traceConversation(startId: Int) -> [FloorPresentation] {
        var forwardId: Int? = startId
        var backwardId: Int? = startId
        var conversation: [FloorPresentation] = []
        
        // trace forward
        while let floorId = forwardId {
            if let presentation = floors.first(where: { $0.floor.id == floorId }) {
                conversation.append(presentation)
                forwardId = presentation.replyTo
            } else { // no matching floor is found, end searching
                break
            }
        }
        
        conversation = conversation.reversed()
        
        // trace backward
        while true {
            if let presentation = floors.first(where: { $0.replyTo == backwardId }) {
                conversation.append(presentation)
                backwardId = presentation.floor.id
            } else { // no match found, end searching
                break
            }
        }
        
        return conversation
    }
    
    // MARK: - Reply
    
    func reply(content: String) async throws {
        _ = try await ForumAPI.createFloor(content: content, holeId: hole.id)
        self.endReached = false
        Task {
            try? await self.loadAllFloors()
        }
    }
    
    // MARK: - Scrolling
    
    let initialScroll: Int?
    
    let scrollControl = PassthroughSubject<UUID, Never>()
    
    @MainActor
    func scrollTo(floorId: Int) {
        if let presentation = floors.filter({ $0.floor.id == floorId }).first {
            scrollControl.send(presentation.id)
        }
    }
    
    // MARK: - Subscription
    
    @Published var subscribed: Bool
    
    @MainActor
    func toggleSubscribe() async throws {
        try await SubscriptionStore.shared.toggleSubscription(hole.id)
        subscribed.toggle()
    }
    
    // MARK: - Favorite
    
    @Published var isFavorite: Bool
    
    @MainActor
    func toggleFavorite() async throws {
        try await FavoriteStore.shared.toggleFavorite(hole.id)
        isFavorite.toggle()
    }
}
