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
    @State private var loadingError: Error? = nil
    @State private var loadID = 0
    @State private var refreshing = false
    
    private func loadMore() async {
        let requestID = loadID
        do {
            let newItems = try await action(items)
            try Task.checkCancellation()
            guard requestID == loadID else { return }
            endReached = newItems.isEmpty
            items += newItems
            loadID += 1
        } catch {
            if requestID == loadID && !Task.isCancelled && !error.isCancellation {
                loadingError = error
            }
        }
    }

    var body: some View {
        style.layout(AnyView(contents), AnyView(footer))
            .refreshable {
                refreshing = true
                loadID += 1
                items = []
                endReached = false
                loadingError = nil
                defer { refreshing = false }
                await loadMore()
            }
    }

    private var contents: some View {
        ForEach(items) { item in
            content(item)
        }
    }

    @ViewBuilder
    private var footer: some View {
        if !endReached {
            if let loadingError = self.loadingError {
                style.contentStyle.errorView(loadingError) {
                    loadingError = nil
                }
            } else if refreshing {
                style.contentStyle.loadingView()
            } else {
                style.contentStyle.loadingView()
                    .task(id: loadID) {
                        await loadMore()
                    }
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
    
    @State private var loadingError: Error? = nil
    @State private var loadID = 0
    
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
        do {
            try await loadingAction()
            try Task.checkCancellation()
            loadID += 1
        } catch {
            if !Task.isCancelled && !error.isCancellation {
                loadingError = error
            }
        }
    }

    var body: some View {
        style.layout(AnyView(contents), AnyView(footer))
    }

    private var contents: some View {
        ForEach(items) { item in
            content(item)
        }
    }

    @ViewBuilder
    private var footer: some View {
        if !endReached {
            if let loadingError = self.loadingError {
                style.contentStyle.errorView(loadingError) {
                    loadingError = nil
                }
            } else {
                style.contentStyle.loadingView()
                    .task(id: loadID) {
                        await loadMore()
                    }
            }
        }
    }
}

private extension Error {
    var isCancellation: Bool {
        if self is CancellationError { return true }
        if let urlError = self as? URLError, urlError.code == .cancelled { return true }
        return false
    }
}
