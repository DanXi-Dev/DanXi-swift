import Foundation

@MainActor
class BrowseViewModel: ObservableObject {
    enum SortOptions {
        case byReplyTime
        case byCreateTime
    }
    
    var preference = Preference.shared
    
    @Published var currentDivision: THDivision
    @Published var holes: [THHole]
    @Published var sortOption: SortOptions = .byReplyTime
    @Published var baseDate: Date?
    @Published var endReached = false
    
    @Published var loading = false
    @Published var errorInfo = ""
    
    
    var filteredHoles: [THHole] {
        holes.filter { hole in
            // filter for blocked tags
            for tagName in hole.tags.map({ $0.name }) {
                if !preference.blockedTags.filter({ $0 == tagName }).isEmpty {
                    return false
                }
            }
            
            // filter for NSFW tags
            return !(preference.nsfwSetting == .hide && hole.nsfw)
        }
    }
    
    init(holes: [THHole] = []) {
        self.holes = holes
        self.currentDivision = TreeholeDataModel.shared.divisions.first!
    }
    
    func loadMoreHoles() async {
        do {
            loading = true
            defer { loading = false }
            
            // set start time
            var startTime: String? = nil
            if !holes.isEmpty {
                startTime = holes.last?.updateTime.ISO8601Format() // TODO: apply sort options
            } else if let baseDate = baseDate {
                startTime = baseDate.ISO8601Format()
            }
            
            // fetch holes
            let newHoles = try await DXNetworks.shared.loadHoles(startTime: startTime, divisionId: currentDivision.id)
            endReached = newHoles.isEmpty
            
            // filter duplicate holes & incorrect division
            let currentIds = holes.map(\.id)
            holes.append(contentsOf: newHoles.filter {
                !currentIds.contains($0.id) && $0.divisionId == currentDivision.id
            })
        } catch {
            errorInfo = error.localizedDescription
        }
    }
    
    func refresh() async {
        holes = []
        endReached = false
        await loadMoreHoles()
    }
}
