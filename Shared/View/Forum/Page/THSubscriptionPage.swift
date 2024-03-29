import SwiftUI

struct THSubscriptionPage: View {
    var body: some View {
        AsyncContentView {
            return try await THRequests.loadSubscriptions()
        } content: { subscriptions in
            SubscriptionContent(subscriptions)
        }
    }
}

fileprivate struct SubscriptionContent: View {
    @ObservedObject private var appModel = THModel.shared
    @State private var subscriptions: [THHole]
    @State private var showAlert = false
    @State private var deleteError = ""
    
    init(_ subscriptions: [THHole]) {
        self._subscriptions = State(initialValue: subscriptions)
    }
    
    private func unsubscribe(_ hole: THHole) {
        Task { @MainActor in
            do {
                try await appModel.deleteSubscription(hole.id)
                if let idx = subscriptions.firstIndex(of: hole) {
                    subscriptions.remove(at: idx)
                }
            } catch {
                deleteError = error.localizedDescription
                showAlert = true
            }
        }
    }
    
    var body: some View {
        Group {
            if subscriptions.isEmpty {
                Text("Empty Subscription List")
                    .foregroundColor(.secondary)
            } else {
                THBackgroundList {
                    ForEach(subscriptions) { hole in
                        THHoleView(hole: hole)
                            .swipeActions {
                                Button(role: .destructive) {
                                    unsubscribe(hole)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                    }
                    .alert("Remove Subscription Error", isPresented: $showAlert) {
                        
                    } message: {
                        Text(deleteError)
                    }
                }
            }
        }
        .navigationTitle("Subscription List")
    }
}
