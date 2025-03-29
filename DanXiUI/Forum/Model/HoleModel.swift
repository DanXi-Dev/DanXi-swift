import Combine
import SwiftUI
import DanXiKit

class HoleModel: ObservableObject {
    @MainActor
    init(hole: Hole) {
        self.hole = hole
        self.floors = []
        self.initialScroll = nil
        self.isFavorite = FavoriteStore.shared.isFavorite(hole.id)
        self.subscribed = SubscriptionStore.shared.isSubscribed(hole.id)
    }
    
    @MainActor
    init(hole: Hole, floors: [Floor], scrollTo: Int? = nil) {
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
        
        filterFloors()
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
    
    @MainActor
    func replaceAllFloors(floors: [FloorPresentation]) {
        self.floors = floors
    }
    
    @MainActor
    func setEndReached(_ value: Bool) {
        self.endReached = value
    }
    
    @MainActor
    func setLoadingAll(_ value: Bool) {
        self.loadingAll = value
    }
    
    func loadMoreFloors() async throws {
        if endReached { return }
        
        let previousCount = filteredFloors.count
        while previousCount == filteredFloors.count {
            let newFloors = try await ForumAPI.listFloorsInHole(holeId: hole.id, startFloor: floors.count)
            if newFloors.isEmpty {
                await setEndReached(true)
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
    
    func refreshAllFloors() async throws {
        let hole = try await ForumAPI.getHole(id: hole.id)
        let floors = try await ForumAPI.listAllFloors(holeId: hole.id)
        var presentations: [FloorPresentation] = []
        for (index, floor) in floors.enumerated() {
            let presentation = FloorPresentation(floor: floor, storey: index + 1, floors: floors)
            presentations.append(presentation)
        }
        await replaceAllFloors(floors: presentations)
        await setEndReached(true)
        await MainActor.run {
            self.hole = hole
        }
    }
    
    func loadAllFloors() async throws {
        await setLoadingAll(true)
        defer {
            Task { @MainActor in
                loadingAll = false
            }
        }
        let floors = try await ForumAPI.listAllFloors(holeId: hole.id)
        var presentations: [FloorPresentation] = []
        for (index, floor) in floors.enumerated() {
            let presentation = FloorPresentation(floor: floor, storey: index + 1, floors: floors)
            presentations.append(presentation)
        }
        await insertFloors(floors: presentations)
        await setEndReached(true)
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
    
    @Published var filteredFloors: [FloorPresentation] = [] {
        didSet {
            groupHoleSegments()
        }
    }
    
    @Published var filteredSegments: [HoleSegment] = []
    
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
            filteredFloors = floors.filter { $0.replyTo == floorId || $0.floor.id == floorId }
        }
    }
    
    private func groupHoleSegments() {
        guard !filteredFloors.isEmpty else {
            filteredSegments = []
            return
        }
        
        var segments: [HoleSegment] = [.floor(filteredFloors[0])] // first floor is not folded, in order to display tags properly
        let presentations = filteredFloors[1...]
        var accumulatedFoldedFloors: [FloorPresentation] = []
        
        for presentation in presentations {
            if presentation.floor.collapse {
                accumulatedFoldedFloors.append(presentation)
            } else {
                if !accumulatedFoldedFloors.isEmpty {
                    let item: HoleSegment = if accumulatedFoldedFloors.count == 1 {
                        .floor(accumulatedFoldedFloors[0])
                    } else {
                        .folded(accumulatedFoldedFloors)
                    }
                    segments.append(item)
                    accumulatedFoldedFloors = []
                }
                segments.append(.floor(presentation))
            }
        }
        
        if !accumulatedFoldedFloors.isEmpty {
            let item: HoleSegment = if accumulatedFoldedFloors.count == 1 {
                .floor(accumulatedFoldedFloors[0])
            } else {
                .folded(accumulatedFoldedFloors)
            }
            segments.append(item)
        }
        
        self.filteredSegments = segments
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
    
    func reply(content: String, specialTag: String = "") async throws {
        let floor = try await ForumAPI.createFloor(content: content, holeId: hole.id, specialTag: specialTag)
        await setEndReached(false)
        Task {
            try? await self.loadAllFloors()
            await scrollTo(floorId: floor.id)
        }
    }
    
    // MARK: - Scrolling
    
    @Published var initialScroll: Int?
    
    /// The floor where you click the MentionView.
    @Published var scrollFrom: FloorPresentation?
    var targetFloorId: UUID? = nil
    @Published var targetFloorVisibility: Bool = true
    
    let scrollControl = PassthroughSubject<UUID, Never>()
    
    @MainActor
    func scrollTo(floorId: Int) {
        if let presentation = floors.filter({ $0.floor.id == floorId }).first {
            scrollControl.send(presentation.id)
            targetFloorId = presentation.id
        }
    }
    
    @MainActor
    func scrollToBottom() {
        if let lastId = floors.last?.id {
            scrollControl.send(lastId)
            targetFloorId = lastId
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
    
    // MARK: - Floor Editing
    
    @MainActor
    private func replaceFloor(floor: Floor) {
        let idx = floors.firstIndex { $0.floor.id == floor.id }
        if let idx {
            let presentation = FloorPresentation(floor: floor, storey: floors[idx].storey, floors: floors.map(\.floor))
            floors[idx] = presentation
        }
    }
    
    func modifyFloor(floorId: Int, content: String, specialTag: String? = nil, fold: String? = nil) async throws {
        let floor = try await ForumAPI.modifyFloor(id: floorId, content: content, specialTag: specialTag, fold: fold)
        await replaceFloor(floor: floor)
    }
    
    func deleteFloor(floorId: Int) async throws {
        let floor = try await ForumAPI.deleteFloor(id: floorId)
        await replaceFloor(floor: floor)
    }
    
    func restoreFloor(floorId: Int, historyId: Int, reason: String) async throws {
        let floor = try await ForumAPI.restoreFloor(id: floorId, historyId: historyId, reason: reason)
        await replaceFloor(floor: floor)
    }
    
    func punish(floorId: Int, reason: String, days: Int) async throws {
        let floor = try await ForumAPI.deleteFloor(id: floorId, reason: reason)
        await replaceFloor(floor: floor)
        if days > 0 {
            try await ForumAPI.penaltyForFloor(id: floorId, reason: reason, days: days)
        }
    }
    
    func permanentPunish(floorId: Int, reason: String) async throws {
        let floor = try await ForumAPI.deleteFloor(id: floorId, reason: reason)
        await replaceFloor(floor: floor)
        try await ForumAPI.permanentPenaltyForFloor(id: floorId, reason: reason)
    }
    
    // MARK: Sheets
    
    @Published var showReplySheet = false
    @Published var showQuestionSheet = false
    @Published var showHoleEditSheet = false
    @Published var showHideAlert = false
    @Published var showCopySheet = false
    @Published var draftReplySheet: Reply? = nil
    @Published var replySheet: Floor? = nil
    @Published var editSheet: Floor? = nil
    @Published var reportSheet: FloorPresentation? = nil
    @Published var deleteSheet: FloorPresentation? = nil
    @Published var historySheet: Floor? = nil
    @Published var textSelectionSheet: Floor? = nil
    
    @Published var deleteAlertItem: Floor?
    var showDeleteAlert: Bool {
        get { deleteAlertItem != nil }
        set {
            // do nothing
        }
    }
}
