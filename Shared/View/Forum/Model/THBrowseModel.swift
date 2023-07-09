import SwiftUI

@MainActor
class THBrowseModel: ObservableObject {
    init() {
        self.bannedDivision = DXModel.shared.user?.banned ?? [:]
    }
    
    // MARK: - Hole Loading
    
//    @Published var endReached = false
    @Published var holes: [THHole] = []
    @Published var configId = UUID() // represent current configuration, when it changes, old holes should not be inserted
    
    private func insertHoles(_ holes: [THHole]) {
        let currentIds = self.holes.map(\.id)
        let insertedHoles = holes.filter { !currentIds.contains($0.id) }
        self.holes.append(contentsOf: insertedHoles)
    }
    
    func loadMoreHoles() async throws {
        let configId = self.configId
        
        // fetch holes
        let prevCount = filteredHoles.count
        repeat {
            // set start time
            var startTime: String? = nil
            if !holes.isEmpty {
                startTime = holes.last?.updateTime.ISO8601Format() // TODO: apply sort options
            } else if let baseDate = baseDate {
                startTime = baseDate.ISO8601Format()
            }
            
            // request, receive and insert
            let newHoles = try await THRequests.loadHoles(startTime: startTime, divisionId: division.id)
            guard configId == self.configId else { return }
            insertHoles(newHoles)
        } while filteredHoles.count != prevCount
    }
    
    func refresh() async {
        do {
            try await THModel.shared.refreshDivisions()
            
            if let currentDivision = THModel.shared.divisions.filter({ $0.id == self.division.id }).first {
                self.division = currentDivision
            }
            self.holes = []
        } catch {
            
        }
    }
    
    // MARK: - Division
    
    @Published var division: THDivision = THModel.shared.divisions.first! {
        didSet {
            self.holes = []
            self.configId = UUID()
        }
    }
    
    let bannedDivision: Dictionary<Int, Date>
    
    var bannedDate: Date? {
        bannedDivision[division.id]
    }
    
    // MARK: - Hole Sort & Filter
    
    enum SortOption {
        case replyTime
        case createTime
    }
    
    @Published var sortOption = SortOption.createTime {
        didSet {
            self.holes = []
            self.configId = UUID()
        }
    }
    @Published var baseDate: Date? {
        didSet {
            self.holes = []
            self.configId = UUID()
        }
    }
    
    var filteredHoles: [THHole] {
        holes.filter { hole in
            let settings = THSettings.shared
            
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
            if hole.nsfw && settings.sensitiveContent == .hide {
                return false
            }
            
            // filter locally blocked holes
            if settings.blockedHoles.contains(hole.id) {
                return false
            }
            
            return true
        }
    }
}
