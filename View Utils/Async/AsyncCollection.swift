import SwiftUI

public struct AsyncCollection<Item: Identifiable & Sendable, Content: View>: View {
    private let nestedView: AnyView
    
    public init(style: AsyncCollectionStyle = .plain,
                action: @escaping ([Item]) async throws -> [Item],
                @ViewBuilder content: @escaping (Item) -> Content) {
        nestedView = AnyView(SimpleAsyncCollection(style: style, action: action, content: content))
    }
    
    public init(style: AsyncCollectionStyle = .plain,
                _ items: [Item],
                endReached: Bool,
                action: @escaping () async throws -> Void,
                @ViewBuilder content: @escaping (Item) -> Content) {
        nestedView = AnyView(ComplexAsyncCollection(style: style, items, endReached: endReached, action: action, content: content))
    }
    
    public var body: some View {
        nestedView
    }
}

private struct SimpleAsyncCollection<Item: Identifiable & Sendable, Content: View>: View {
    let style: AsyncCollectionStyle
    let action: ([Item]) async throws -> [Item]
    let content: (Item) -> Content
    
    
    @State private var items: [Item] = []
    @State private var endReached = false
    @State private var loading = false
    @State private var loadingError: Error? = nil
    
    private func loadMore() async {
        do {
            loadingError = nil
            loading = true
            defer { loading = false }
            let newItems = try await action(items)
            endReached = newItems.isEmpty
            items += newItems
        } catch {
            if !Task.isCancelled {
                loadingError = error
            }
        }
    }
    
    var body: some View {
        style.layout(AnyView(contents), AnyView(footer))
            .task {
                await loadMore()
            }
            .refreshable {
                items = []
                await loadMore()
            }
    }
    
    private var contents: some View {
        Group {
            ForEach(items) { item in
                content(item)
                    .task {
                        if item.id == items.last?.id {
                            await loadMore()
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    private var footer: some View {
        if !endReached {
            if let loadingError = self.loadingError {
                style.contentStyle.errorView(loadingError) {
                    Task.detached {
                        await loadMore()
                    }
                }
            } else {
                style.contentStyle.loadingView()
            }
        }
    }
}

private struct ComplexAsyncCollection<Item: Identifiable, Content: View>: View {
    private let style: AsyncCollectionStyle
    private let items: [Item]
    private let content: (Item) -> Content
    private let loadingAction: () async throws -> Void
    private let endReached: Bool
    
    @State private var loading = false
    @State private var loadingError: Error? = nil
    
    init(style: AsyncCollectionStyle,
         _ items: [Item],
         endReached: Bool,
         action: @escaping () async throws -> Void,
         @ViewBuilder content: @escaping (Item) -> Content) {
        self.style = style
        self.items = items
        self.endReached = endReached
        self.loadingAction = action
        self.content = content
    }
    
    private func loadMore() async {
        guard !loading else { return } // prevent parallel loading task
        
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
        style.layout(AnyView(contents), AnyView(footer))
            .task {
                await loadMore()
            }
            .onChange(of: items.count) { count in
                if count == 0 { // automatically handles refresh
                    Task { await loadMore() }
                }
            }
    }
    
    private var contents: some View {
        Group {
            ForEach(items) { item in
                content(item)
                    .task {
                        if item.id == items.last?.id {
                            await loadMore()
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    private var footer: some View {
        if !endReached {
            if let loadingError = self.loadingError {
                style.contentStyle.errorView(loadingError) {
                    Task.detached {
                        await loadMore()
                    }
                }
            } else {
                style.contentStyle.loadingView()
            }
        }
    }
}
