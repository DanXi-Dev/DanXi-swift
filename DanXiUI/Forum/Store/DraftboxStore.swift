import DanXiKit
import Disk
import SwiftUI

/// A centralized object for accessing and modifying the user's draft post & replies.
class DraftboxStore {
    static let shared = DraftboxStore()
    private var cachedDraftbox: Draftbox?

    /// `Draftbox` object managed with caching and persistent storage.
    ///
    /// This property should only be accessed from background threads due to potential
    /// disk I/O operations. Avoid accessing this from the main thread to prevent
    /// blocking the user interface.
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
            draftbox.replies.filter { reply in
                holeId == reply.holeId && replyTo == reply.replyTo
            }.first
        }
        return await task.value
    }

    func getPost() async -> Post? {
        let task = Task {
            draftbox.post
        }
        return await task.value
    }

    func deletePostDraft() async {
        let task = Task {
            draftbox = Draftbox(post: nil, replies: draftbox.replies)
        }
        return await task.value
    }

    func deleteReplyDraft(holeId: Int, replyTo: Int? = nil) async {
        let task = Task {
            // delete the reply in the draft box
            let newReplies = draftbox.replies.filter { reply in
                holeId != reply.holeId || replyTo != reply.replyTo
            }
            draftbox = Draftbox(post: draftbox.post, replies: newReplies)
        }
        return await task.value
    }
}

/// A `Draftbox` represents the storage of a user's draft content in the forum.
struct Draftbox: Codable {
    let post: Post?
    let replies: [Reply]
}

/// A `Post` represents a created Hole with content and associated tags.
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

/// A `Reply` represents a reply to a Hole, which may optionally reference another reply.
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
