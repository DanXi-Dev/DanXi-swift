import SwiftUI
import DanXiKit
import Disk

class SubscriptionStore: ObservableObject {
    static let shared = SubscriptionStore()
    
    var subscriptionIds: [Int]
    
    init() {
        if let subscriptionIds = try? Disk.retrieve("fduhole/subscriptions.json", from: .applicationSupport, as: [Int].self) {
            self.subscriptionIds = subscriptionIds
        } else {
            self.subscriptionIds = []
        }
    }
    
    @MainActor
    private func set(subscriptionIds: [Int]) {
        self.subscriptionIds = subscriptionIds
    }
    
    func isSubscribed(_ id: Int) -> Bool {
        subscriptionIds.contains(id)
    }
    
    func toggleSubscription(_ id: Int) async throws {
        let ids = if isSubscribed(id) {
            try await ForumAPI.addSubscription(holeId: id)
        } else {
            try await ForumAPI.deleteSubscription(holeId: id)
        }
        await set(subscriptionIds: ids)
        try? Disk.save(ids, to: .applicationSupport, as: "fduhole/subscriptions.json")
    }
    
    func clear() async {
        await set(subscriptionIds: [])
        try? Disk.remove("fduhole/subscriptions.json", from: .applicationSupport)
    }
}
