import Foundation
import DanXiKit

struct ForumBrowseHistory: Identifiable, Hashable, Codable {
    let id: Int
    let view, reply: Int
    let tags: [String]
    let content: String
    let lastBrowsed: Date
    
    init(_ hole: Hole) {
        self.id = hole.id
        self.view = hole.view
        self.reply = hole.reply
        self.tags = hole.tags.map(\.name)
        self.content = hole.firstFloor.content
        self.lastBrowsed = Date.now
    }
}

