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
    @Published var submitted = false {
        didSet {
            if submitted {
                if let matchFloor = matchFloor {
                    navLoader = THHoleLoader(floorId: matchFloor)
                    submitted = false // prevent showing search page after navigation
                } else if let matchHole = matchHole {
                    navLoader = THHoleLoader(holeId: matchHole)
                    submitted = false // prevent showing search page after navigation
                }
            }
        }
    }
    @Published var history: [String] = []
    @Published var navLoader: THHoleLoader? = nil // used to automatically jump to hole page when search text is an ID
    
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
        THModel.shared.tags.filter { $0.name.contains(searchText) }
    }
    
    func appendHistory(_ history: String) {
        if let index = self.history.firstIndex(of: history) {
            self.history.remove(at: index)
        }
        
        self.history.insert(history, at: 0)
        persistHistory()
    }
    
    func removeHistory(_ history: String) {
        if let index = self.history.firstIndex(of: history) {
            self.history.remove(at: index)
        }
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
