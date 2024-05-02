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
            configurationId = UUID()
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
            self.holes = []
        }
    }
    
    // MARK: - Holes
    
    @Published var configurationId = UUID()
    
    @Published var sortOption = SortOption.replyTime {
        didSet {
            holes = []
            configurationId = UUID()
        }
    }
    
    @Published var baseDate: Date? {
        didSet {
            holes = []
            configurationId = UUID()
        }
    }
    
    @Published var holes: [Hole] = []
    
    var filteredHoles: [Hole] {
        return holes.filter { hole in
            let settings = ForumSettings.shared
            
            // filter for blocked tags
            let tagsSet = Set(hole.tags.map(\.name))
            let blockedSet = Set(settings.blockedTags)
            if !blockedSet.intersection(tagsSet).isEmpty {
                return false
            }
            
            // filter pinned hole
            if division.pinned.map(\.id).contains(hole.id) {
                return false
            }
            
            // filter NSFW tag
            let hasSensitiveTag = hole.tags.contains(where: { $0.name.starts(with: "*") })
            if hasSensitiveTag && settings.sensitiveContent == .hide {
                return false
            }
                        
            // filter locally blocked holes
            if settings.blockedHoles.contains(hole.id) {
                return false
            }
            
            return true
        }
    }
    
    @MainActor
    private func insertHoles(holes: [Hole]) {
        let currentIds = self.holes.map(\.id)
        let filtered = holes.filter { !currentIds.contains($0.id) }
        self.holes += filtered
    }
    
    func loadMoreHoles() async throws {
        let previousCount = filteredHoles.count
        let configurationId = self.configurationId
        
        repeat {
            let startTime: Date? = if !holes.isEmpty {
                sortOption == .replyTime ? holes.last?.timeUpdated : holes.last?.timeCreated
            } else if let baseDate {
                baseDate
            } else {
                nil
            }
            
            let newHoles = try await ForumAPI.listHolesInDivision(divisionId: division.id, startTime: startTime, order: sortOption == .replyTime ? "time_updated" : "time_created")
            guard configurationId == self.configurationId else { return }
            await insertHoles(holes: newHoles)
        } while filteredHoles.count == previousCount
    }
}
