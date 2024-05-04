import SwiftUI
import Disk
import DanXiKit

class TagStore: ObservableObject {
    static let shared = TagStore()
    
    @Published var tags: [Tag]
    var initialized = false
    
    init() {
        if let tags = try? Disk.retrieve("fduhole/tags.json", from: .appGroup, as: [Tag].self) {
            self.tags = tags
        } else {
            self.tags = []
        }
    }
    
    @MainActor
    private func set(tags: [Tag]) {
        self.tags = tags
    }
    
    func refreshTags() async throws {
        let tags = try await ForumAPI.listAllTags()
        try Disk.save(tags, to: .appGroup, as: "fduhole/tags.json")
        await set(tags: tags)
        initialized = true
    }
    
    func clear() async {
        await set(tags: [])
        try? Disk.remove("fduhole/tags.json", from: .appGroup)
        initialized = false
    }
}
