import SwiftUI
import Disk
import DanXiKit

@MainActor
class HistoryStore: ObservableObject {
    static let shared = HistoryStore()
    
    @Published var browseHistory: [ForumBrowseHistory]
    
    init() {
        if let browseHistory = try? Disk.retrieve("fduhole/history.json", from: .applicationSupport, as: [ForumBrowseHistory].self) {
            self.browseHistory = browseHistory
        } else {
            self.browseHistory = []
        }
    }
    
    func saveHistory(hole: Hole) {
        let history = ForumBrowseHistory(hole)
        if let index = browseHistory.firstIndex(where: { $0.id == history.id }) {
            browseHistory.remove(at: index)
        }
        browseHistory.insert(history, at: 0)
        
        if browseHistory.count > 200 {
            browseHistory.removeSubrange(200...) // only keep recent 200 records
        }
        
        Task {
            // save to disk, perform on background task
            try Disk.save(browseHistory, to: .applicationSupport, as: "fduhole/history.json")
        }
    }
    
    func clearHistory() {
        browseHistory = []
        try? Disk.save(browseHistory, to: .applicationSupport, as: "fduhole/history.json")
    }
}
