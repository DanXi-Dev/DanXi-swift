import SwiftUI
import DanXiKit

@MainActor
class BrowseModel: ObservableObject {
    @AppStorage("forum-browse-option") private var savedBrowseOption = BrowseOption.division

    init(division: Division) {
        self.division = division
        self.browseOption = savedBrowseOption
    }
    
    // MARK: - Divisions
    
    @Published var division: Division {
        didSet {
            // `refresh` reassigns the same division with updated info, which should not reset the list
            if oldValue.id != division.id {
                resetHoleList()
            }
        }
    }
    
    enum SortOption {
        case replyTime
        case createTime
    }

    enum BrowseOption: String {
        case division
        case sitewide
    }
    
    /// Fetch the first page before replacing the list, instead of emptying it and loading again.
    /// Otherwise the list collapses and refills while the refresh control is still animating back,
    /// which makes the navigation bar and search field bounce back late.
    func refresh() async throws {
        self.generation = UUID()
        let generation = self.generation
        refreshing = true
        defer {
            if generation == self.generation {
                refreshing = false
            }
        }
        try await DivisionStore.shared.refreshDivisions()
        try Task.checkCancellation()
        guard generation == self.generation else { return }
        if let currentDivision = DivisionStore.shared.divisions.first(where: { $0.id == division.id }) {
            division = currentDivision
        }
        let newHoles = try await listHoles(startTime: baseDate)
        try Task.checkCancellation()
        guard generation == self.generation else { return }
        holes = filterAndConstructHoles(holes: newHoles)
        nextStartTime = cursor(after: newHoles)
        endReached = newHoles.isEmpty
    }

    // MARK: - Holes
    
    @Published var configurationId = UUID()
    
    @Published var sortOption = SortOption.replyTime {
        didSet {
            resetHoleList()
        }
    }

    @Published var browseOption = BrowseOption.division {
        didSet {
            savedBrowseOption = browseOption
            resetHoleList()
        }
    }
    
    @Published var baseDate: Date? {
        didSet {
            resetHoleList()
        }
    }
    
    @Published var holes: [HolePresentation] = []
    @Published var endReached = false
    @Published private(set) var refreshing = false
    private var generation = UUID()
    private var nextStartTime: Date?
    
    private func resetHoleList() {
        generation = UUID()
        configurationId = UUID()
        holes = []
        endReached = false
        refreshing = false
        nextStartTime = baseDate
    }

    private func cursor(after holes: [Hole]) -> Date? {
        sortOption == .replyTime ? holes.last?.timeUpdated : holes.last?.timeCreated
    }

    private func insertHoles(holes: [HolePresentation]) {
        let currentIds = self.holes.map(\.id)
        let filtered = holes.filter { !currentIds.contains($0.id) }
        self.holes += filtered
    }

    private func listHoles(startTime: Date?) async throws -> [Hole] {
        let order = sortOption == .replyTime ? "time_updated" : "time_created"
        switch browseOption {
        case .division:
            return try await ForumAPI.listHolesInDivision(divisionId: division.id, startTime: startTime, order: order)
        case .sitewide:
            return try await ForumAPI.listHoles(startTime: startTime, order: order)
        }
    }
    
    private func filterAndConstructHoles(holes: [Hole]) -> [HolePresentation] {
        holes.compactMap { hole in
            let settings = ForumSettings.shared
            
            // filter for blocked tags
            let tagsSet = Set(hole.tags.map(\.name))
            let blockedSet = Set(settings.blockedTags)
            if !blockedSet.intersection(tagsSet).isEmpty {
                return nil
            }
            
            // filter pinned hole
            if browseOption == .division && division.pinned.map(\.id).contains(hole.id) {
                return nil
            }
            
            // filter tags with "*"
            let hasSensitiveTag = hole.tags.contains(where: { $0.name.starts(with: "*") })
            if hasSensitiveTag && settings.foldedContent == .hide {
                return nil
            }
                        
            // filter locally blocked holes
            if settings.blockedHoles.contains(hole.id) {
                return nil
            }
            
            return HolePresentation(hole: hole)
        }
    }
    
    func loadMoreHoles() async throws {
        let previousCount = holes.count
        let generation = self.generation

        repeat {
            let newHoles = try await listHoles(startTime: nextStartTime)
            try Task.checkCancellation()
            guard generation == self.generation else { return }
            if newHoles.isEmpty {
                endReached = true
                return
            }
            nextStartTime = cursor(after: newHoles)
            let filteredHoles = filterAndConstructHoles(holes: newHoles)
            insertHoles(holes: filteredHoles)
        } while holes.count == previousCount
    }
}
