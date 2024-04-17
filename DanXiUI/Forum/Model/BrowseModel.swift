import SwiftUI
import DanXiKit

class BrowseModel: ObservableObject {
    
    private actor Loader {
        var task: Task<[Hole], any Error>? = nil
        
        func load(loader: @escaping () async throws -> [Hole]) async -> Task<[Hole], any Error> {
            if let task {
                _ = try? await task.value
            }
            
            let task = Task {
                return try await loader()
            }
            self.task = task
            return task
        }
    }
    
    init(divisions: [Division], division: Division, bannedDivisions: [Int : Date], holes: [Hole]) {
        self.divisions = divisions
        self.division = division
        self.bannedDivisions = bannedDivisions
        self.holes = holes
    }
    
    private let loader = Loader()
    
    // MARK: - Divisions
    
    @Published var divisions: [Division]
    
    @Published var division: Division {
        didSet {
            configurationId = UUID()
        }
    }
    
    let bannedDivisions: [Int: Date]
    
    var bannedDate: Date? {
        bannedDivisions[division.id]
    }
    
    enum SortOption {
        case replyTime
        case createTime
    }
    
    func refresh() async throws {
        // TODO: Finish this
    }
    
    // MARK: - Holes
    
    private var configurationId = UUID()
    
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
    
    // TODO: Finish this
//    var filteredHoles: [Hole] {
//
//    }
    
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
