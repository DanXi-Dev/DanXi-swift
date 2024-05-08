import SwiftUI
import ViewUtils
import DanXiKit

struct SubscriptionPage: View {
    var body: some View {
        AsyncContentView { _ in
            let holes = try await ForumAPI.listSubscriptions()
            return holes.map { HolePresentation(hole: $0) }
        } content: { subscriptions in
            SubscriptionContent(subscriptions)
                .watermark()
        }
    }
}

private struct SubscriptionContent: View {
    @ObservedObject private var subscriptionStore = SubscriptionStore.shared
    @State private var subscriptions: [HolePresentation]
    @State private var showAlert = false
    @State private var deleteError = ""

    init(_ subscriptions: [HolePresentation]) {
        self._subscriptions = State(initialValue: subscriptions)
    }

    private func unsubscribe(_ presentation: HolePresentation) {
        Task { @MainActor in
            do {
                try await subscriptionStore.toggleSubscription(presentation.id)
                let idx = subscriptions.firstIndex(where: { $0.id == presentation.id })
                if let idx {
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
                    ForEach(subscriptions) { presentation in
                        Section {
                            HoleView(presentation: presentation)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        unsubscribe(presentation)
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
