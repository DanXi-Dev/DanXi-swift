import SwiftUI
import Disk
import DanXiKit
import Combine

@MainActor
class SearchModel: ObservableObject {
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
                navigate()
            }
        }
    }
    @Published var history: [String]
    
    init() {
        if let cachedHistory = try? Disk.retrieve("fduhole/search-history.json", from: .applicationSupport, as: [String].self) {
            history = cachedHistory
        } else {
            history = []
        }
    }
    
    let navigationPublisher = PassthroughSubject<HoleLoader, Never>()
    
    func navigate() {
        if let matchFloor = matchFloor {
            let loader = HoleLoader(floorId: matchFloor)
            navigationPublisher.send(loader)
            submitted = false // prevent showing search page after navigation
        } else if let matchHole = matchHole {
            let loader = HoleLoader(holeId: matchHole)
            navigationPublisher.send(loader)
            submitted = false // prevent showing search page after navigation
        }
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
    
    var matchTags: [Tag] {
        TagStore.shared.tags.filter { $0.name.contains(searchText) }
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
            try Disk.save(self.history, to: .applicationSupport, as: "fduhole/search-history.json")
        }
    }
}
