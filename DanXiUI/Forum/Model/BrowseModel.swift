import SwiftUI
import DanXiKit

class BrowseModel: ObservableObject {
    @MainActor
    init(division: Division) {
        self.division = division
    }
    
    // MARK: - Divisions
    
    @Published var division: Division {
        didSet {
            resetHoleList()
        }
    }
    
    enum SortOption {
        case replyTime
        case createTime
    }
    
    func refresh() async throws {
        try await DivisionStore.shared.refreshDivisions()
        await MainActor.run {
            if let currentDivision = DivisionStore.shared.divisions.filter({ $0.id == self.division.id }).first {
                self.division = currentDivision
            }
            resetHoleList()
        }
    }
    
    // MARK: - Holes
    
    @Published var configurationId = UUID()
    
    @Published var sortOption = SortOption.replyTime {
        didSet {
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
    
    private func resetHoleList() {
        Task { @MainActor in
            holes = []
            configurationId = UUID()
            endReached = false
        }
    }
    
    @MainActor
    private func setEndReached(_ endReached: Bool) {
        self.endReached = endReached
    }
    
    @MainActor
    private func insertHoles(holes: [HolePresentation]) {
        let currentIds = self.holes.map(\.id)
        let filtered = holes.filter { !currentIds.contains($0.id) }
        self.holes += filtered
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
            if division.pinned.map(\.id).contains(hole.id) {
                return nil
            }
            
            // filter NSFW tag
            let hasSensitiveTag = hole.tags.contains(where: { $0.name.starts(with: "*") })
            if hasSensitiveTag && settings.sensitiveContent == .hide {
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
        let configurationId = self.configurationId
        var startTime: Date? = baseDate
        
        repeat {
            let newHoles = try await ForumAPI.listHolesInDivision(divisionId: division.id, startTime: startTime, order: sortOption == .replyTime ? "time_updated" : "time_created")
            if newHoles.isEmpty {
                await setEndReached(true)
                return
            }
            guard configurationId == self.configurationId else { return }
            startTime = sortOption == .replyTime ? newHoles.last?.timeUpdated : newHoles.last?.timeCreated
            let filteredHoles = filterAndConstructHoles(holes: newHoles)
            await insertHoles(holes: filteredHoles)
        } while holes.count == previousCount
    }
}
