import SwiftUI

struct AsyncCollection<Item: Identifiable, Content: View>: View {
    private let nestedView: AnyView
    
    init(action: @escaping ([Item]) async throws -> [Item],
         @ViewBuilder content: @escaping (Item) -> Content) {
        nestedView = AnyView(SimpleAsyncCollection(action: action, content: content))
    }
    
    init(_ items: [Item],
         endReached: Bool,
         action: @escaping () async throws -> Void,
         @ViewBuilder content: @escaping (Item) -> Content) {
        nestedView = AnyView(ComplexAsyncCollection(items, endReached: endReached, action: action, content: content))
    }
    
    var body: some View {
        nestedView
    }
}

fileprivate struct SimpleAsyncCollection<Item: Identifiable, Content: View>: View {
    private let content: (Item) -> Content
    private let loadingAction: ([Item]) async throws -> [Item]
    
    @State private var items: [Item] = []
    @State private var endReached = false
    @State private var loading = false
    @State private var loadingError: Error? = nil
    
    init(action: @escaping ([Item]) async throws -> [Item],
         @ViewBuilder content: @escaping (Item) -> Content) {
        self.loadingAction = action
        self.content = content
    }
    
    private func loadMore() async {
        do {
            loadingError = nil
            loading = true
            defer { loading = false }
            let newItems = try await loadingAction(items)
            endReached = newItems.isEmpty
            items += newItems
        } catch {
            if !Task.isCancelled {
                loadingError = error
            }
        }
    }
    
    var body: some View {
        Group {
            ForEach(items) { item in
                content(item)
                    .task {
                        if item.id == items.last?.id {
                            await loadMore()
                        }
                    }
            }
            
            footer
                .listRowSeparator(.hidden, edges: .bottom)
        }
        .task {
            await loadMore()
        }
        .refreshable {
            items = []
            await loadMore()
        }
    }
    
    @ViewBuilder
    private var footer: some View {
        if !endReached {
            HStack {
                Spacer()
                if let loadingError = self.loadingError {
                    ErrorView(loadingError) {
                        await loadMore()
                    }
                } else {
                    ProgressView()
                }
                Spacer()
            }
        }
    }
}

fileprivate struct ComplexAsyncCollection<Item: Identifiable, Content: View>: View {
    private let items: [Item]
    private let content: (Item) -> Content
    private let loadingAction: () async throws -> Void
    private let endReached: Bool
    
    @State private var loading = false
    @State private var loadingError: Error? = nil
    
    init(_ items: [Item],
         endReached: Bool,
         action: @escaping () async throws -> Void,
         @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.endReached = endReached
        self.loadingAction = action
        self.content = content
    }
    
    private func loadMore() async {
        do {
            loadingError = nil
            loading = true
            defer { loading = false }
            try await loadingAction()
        } catch {
            loadingError = error
        }
    }
    
    var body: some View {
        Group {
            ForEach(items) { item in
                content(item)
                    .task {
                        if item.id == items.last?.id {
                            await loadMore()
                        }
                    }
            }
            footer
                .listRowSeparator(.hidden, edges: .bottom)
        }
        .task {
            await loadMore()
        }
        .onChange(of: items.count) { count in
            if count == 0 { // automatically handles refresh
                Task { await loadMore() }
            }
        }
    }
    
    @ViewBuilder
    private var footer: some View {
        if !endReached {
            HStack {
                Spacer()
                if let loadingError = self.loadingError {
                    ErrorView(loadingError) {
                        await loadMore()
                    }
                } else if loading {
                    ProgressView()
                }
                Spacer()
            }
        }
    }
}

fileprivate struct ErrorView: View {
    private let action: () async -> Void
    private let error: Error
    
    init(_ error: Error, action: @escaping () async -> Void) {
        self.error = error
        self.action = action
    }
    
    var body: some View {
        VStack {
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button {
                Task {
                    await action()
                }
            } label: {
                Text("Retry")
                    .foregroundColor(.accentColor)
            }
        }
        .font(.caption)
    }
}
