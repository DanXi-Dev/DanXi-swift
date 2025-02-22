import DanXiKit
import Disk
import SwiftUI

class DraftboxStore {
    static let shared = DraftboxStore()
    private var cachedDraftbox: Draftbox?
    
    var draftbox: Draftbox {
        get {
            if let cachedDraftbox {
                return cachedDraftbox
            }
            if let draftboxData = try? Disk.retrieve("fduhole/draftbox.json", from: .applicationSupport, as: Draftbox.self) {
                cachedDraftbox = draftboxData
                return draftboxData
            }
            return Draftbox(post: nil, replies: [])
        }
        set(newValue) {
            let oldReplies = newValue.replies.sorted { $0.createdAt > $1.createdAt }
            let filteredReplies = oldReplies.prefix(10)
            let newDraftbox = Draftbox(post: newValue.post, replies: Array(filteredReplies))
            cachedDraftbox = newDraftbox
            try? Disk.save(newValue, to: .applicationSupport, as: "fduhole/draftbox.json")
        }
    }

    func addPostDraft(content: String, tags: [String]) {
        let newPost = Post(content: content, tags: tags)
        let newDraftbox = Draftbox(post: newPost, replies: draftbox.replies)
        draftbox = newDraftbox
    }

    func addReplyDraft(content: String, holeId: Int, replyTo: Int? = nil) {
        let newReply = Reply(content: content, replyTo: replyTo, holeId: holeId)
        let newDraftbox = Draftbox(post: draftbox.post, replies: draftbox.replies + [newReply])
        draftbox = newDraftbox
    }
    
    func getReply(_ holeId: Int, replyTo: Int? = nil) async -> Reply? {
        let task = Task {
            return draftbox.replies.filter { reply in
                holeId == reply.holeId && replyTo == reply.replyTo
            }.first
        }
        return await task.value
    }
    
    func getPost() async -> Post? {
        let task = Task {
            return draftbox.post
        }
        return await task.value
    }
    
    func deletePostDraft() async -> Void {
        
        let task = Task {
            draftbox = Draftbox(post: nil, replies: draftbox.replies)
        }
        return await task.value
    }
    
    func deleteReplyDraft(holeId: Int, replyTo: Int? = nil) async -> Void {
        let task = Task {
            draftbox = Draftbox(post: draftbox.post, replies: draftbox.replies.filter { reply in
                holeId != reply.holeId || replyTo != reply.replyTo
            })
        }
        return await task.value
    }
    
}

struct Draftbox: Codable {
    let post: Post?
    let replies: [Reply]
}

struct Post: Identifiable, Codable {
    let id: UUID
    let content: String
    let tags: [String]
    
    init(content: String, tags: [String]) {
        self.content = content
        self.tags = tags
        self.id = UUID()
    }
}

struct Reply: Identifiable, Codable {
    let id: UUID
    let content: String
    let replyTo: Int?
    let holeId: Int
    let createdAt: Date
    
    init(content: String, replyTo: Int? = nil, holeId: Int) {
        self.content = content
        self.replyTo = replyTo
        self.holeId = holeId
        self.createdAt = Date()
        self.id = UUID()
    }
}
