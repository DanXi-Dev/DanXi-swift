import SwiftUI
import ViewUtils
import DanXiKit

struct SubscriptionPage: View {
    var body: some View {
        AsyncContentView { _ in
            try await ForumAPI.listSubscriptions()
        } content: { subscriptions in
            SubscriptionContent(subscriptions)
                .watermark()
        }
    }
}

private struct SubscriptionContent: View {
    @ObservedObject private var subscriptionStore = SubscriptionStore.shared
    @State private var subscriptions: [Hole]
    @State private var showAlert = false
    @State private var deleteError = ""

    init(_ subscriptions: [Hole]) {
        self._subscriptions = State(initialValue: subscriptions)
    }

    private func unsubscribe(_ hole: Hole) {
        Task { @MainActor in
            do {
                try await subscriptionStore.toggleSubscription(hole.id)
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
                ForumList {
                    ForEach(subscriptions) { hole in
                        Section {
                            HoleView(hole: hole)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        unsubscribe(hole)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        }
                    }
                    .alert("Remove Subscription Error", isPresented: $showAlert) {} message: {
                        Text(deleteError)
                    }
                }
            }
        }
        .navigationTitle("Subscription List")
        .navigationBarTitleDisplayMode(.inline)
    }
}
