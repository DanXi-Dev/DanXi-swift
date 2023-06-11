import Foundation
import Disk

@MainActor
class THSearchModel: ObservableObject {
    @Published var searchText = "" {
        didSet {
            if self.submitted {
                self.submitted = false
            }
        }
    }
    @Published var submitted = false
    @Published var history: [String] = []
    
    init() {
        let cachedHistory = try? Disk.retrieve("fduhole/search-history.json", from: .applicationSupport, as: [String].self)
        history = cachedHistory ?? []
    }
    
    var matchFloor: Int? {
        if let match = searchText.wholeMatch(of: /##(?<id>\d+)/) {
            return Int(match.id)
        }
        return nil
    }
    
    var matchHole: Int? {
        if let match = searchText.wholeMatch(of: /#(?<id>\d+)/) {
            return Int(match.id)
        }
        return nil
    }
    
    var matchTags: [THTag] {
        DXModel.shared.tags.filter { $0.name.contains(searchText) }
    }
    
    func appendHistory(_ history: String) {
        if let index = self.history.firstIndex(of: history) {
            self.history.remove(at: index)
        }
        
        self.history.insert(history, at: 0)
        persistHistory()
    }
    
    func clearHistory() {
        self.history = []
        persistHistory()
    }
    
    private func persistHistory() {
        Task {
            do {
                try Disk.save(self.history, to: .applicationSupport, as: "fduhole/search-history.json")
            }
        }
    }
}
