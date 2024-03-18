import SwiftUI

// MARK: - View

enum AsyncContentStyle {
    case page, widget
}

struct AsyncContentView<Output, Content: View>: View {
    private let nestedView: AnyView
    
    init(finished: Bool = false,
         style: AsyncContentStyle = .page,
         action: @escaping () async throws -> Void,
         @ViewBuilder content: () -> Content) where Output == Void {
        nestedView = AnyView(AsyncTaskView(finished: finished,
                                           style: style,
                                           action: action,
                                           content: content))
    }
    
    init(style: AsyncContentStyle = .page,
         action: @escaping () async throws -> Output,
         @ViewBuilder content: @escaping (Output) -> Content) {
        nestedView = AnyView(AsyncMappingView(style: style,
                                              action: action,
                                              content: content))
    }
    
    init(finished: Bool = false,
         action: @escaping () async throws -> Void,
         @ViewBuilder content: () -> Content,
         loadingView: (() -> AnyView)?,
         failureView: ((Error, @escaping () -> Void) -> AnyView)?) where Output == Void {
        nestedView = AnyView(AsyncTaskView(finished: finished, action: action, content: content, loadingView: loadingView, failureView: failureView))
    }
    
    init(action: @escaping () async throws -> Output,
         @ViewBuilder content: @escaping (Output) -> Content,
         loadingView: (() -> AnyView)?,
         failureView: ((Error, @escaping () -> Void) -> AnyView)?) {
        nestedView = AnyView(AsyncMappingView(action: action, content: content, loadingView: loadingView, failureView: failureView))
    }
    
    var body: some View {
        nestedView
    }
}

struct AsyncTaskView<Content: View>: View {
    private let style: AsyncContentStyle
    @StateObject private var loader: AsyncLoader<Void>
    private let content: Content
    @ViewBuilder private let loadingView: (() -> (AnyView))?
    @ViewBuilder private let failureView: ((Error, @escaping () -> Void) -> (AnyView))?
    
    init(finished: Bool = false,
         style: AsyncContentStyle = .page,
         action: @escaping () async throws -> Void,
         @ViewBuilder content: () -> Content) {
        let loader = AsyncLoader(action: action)
        if finished {
            loader.state = .loaded(()) // this is a hack: Void is an empty tuple, this is for code reuse
        }
        self._loader = StateObject(wrappedValue: loader)
        self.style = style
        self.content = content()
        self.loadingView = nil
        self.failureView = nil
    }
    
    init(finished: Bool = false,
         action: @escaping () async throws -> Void,
         @ViewBuilder content: () -> Content,
         loadingView: (() -> AnyView)?,
         failureView: ((Error, @escaping () -> Void) -> AnyView)?) {
        let loader = AsyncLoader(action: action)
        if finished {
            loader.state = .loaded(()) // this is a hack: Void is an empty tuple, this is for code reuse
        }
        self._loader = StateObject(wrappedValue: loader)
        self.style = .page
        self.content = content()
        self.loadingView = loadingView
        self.failureView = failureView
    }
    
    var body: some View {
        switch loader.state {
        case .loading:
            if let loadingView = loadingView {
                loadingView()
                    .task {
                        await loader.load()
                    }
            } else {
                LoadingView(style: self.style)
                    .task {
                        await loader.load()
                    }
            }
        case .failed(let error):
            if let failureView = failureView {
                failureView(error) {
                    loader.state = .loading
                }
            } else {
                ErrorView(style: self.style, error: error) {
                    loader.state = .loading
                }
            }
        case .loaded(_):
            content
        }
    }
}

struct AsyncMappingView<Output, Content: View>: View {
    private let style: AsyncContentStyle
    @StateObject private var loader: AsyncLoader<Output>
    private var content: (Output) -> Content
    @ViewBuilder private let loadingView: (() -> (AnyView))?
    @ViewBuilder private let failureView: ((Error, @escaping () -> Void) -> (AnyView))?
    
    init(style: AsyncContentStyle = .page,
         action: @escaping () async throws -> Output,
         @ViewBuilder content: @escaping (Output) -> Content) {
        self.style = style
        self._loader = StateObject(wrappedValue: AsyncLoader(action: action))
        self.content = content
        self.loadingView = nil
        self.failureView = nil
    }
    
    init(action: @escaping () async throws -> Output,
         @ViewBuilder content: @escaping (Output) -> Content,
         loadingView: (() -> AnyView)?,
         failureView: ((Error, @escaping () -> Void) -> AnyView)?) {
        self.style = .page
        self._loader = StateObject(wrappedValue: AsyncLoader(action: action))
        self.content = content
        self.loadingView = loadingView
        self.failureView = failureView
    }
    
    var body: some View {
        switch loader.state {
        case .loading:
            if let loadingView = loadingView {
                loadingView()
                    .task {
                        await loader.load()
                    }
            } else {
                LoadingView(style: self.style)
                    .task {
                        await loader.load()
                    }
            }
        case .failed(let error):
            if let failureView = failureView {
                failureView(error) {
                    loader.state = .loading
                }
            } else {
                ErrorView(style: self.style, error: error) {
                    loader.state = .loading
                }
            }
        case .loaded(let output):
            content(output)
        }
    }
}

fileprivate struct LoadingView: View {
    let style: AsyncContentStyle
    
    var body: some View {
        switch(style) {
        case .page:
            VStack {
                ProgressView()
                Text("Loading")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        case .widget:
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .listRowBackground(Color.clear)
        }
    }
}

fileprivate struct ErrorView: View {
    let style: AsyncContentStyle
    let error: Error
    let retryHandler: () -> Void
    
    init(style: AsyncContentStyle, error: Error, retryHandler: @escaping () -> Void) {
        self.style = style
        self.error = error
        self.retryHandler = retryHandler
    }
    
    var body: some View {
        switch(style) {
        case .page:
            VStack {
                Text("Loading Failed")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(error.localizedDescription)
                    .font(.callout)
                    .padding(.bottom)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                Button {
                    retryHandler()
                } label: {
                    Text("Retry")
                }
                .foregroundStyle(Color.accentColor)
            }
            .padding()
        case .widget:
            HStack {
                Spacer()
                VStack {
                    if let errorDescription = (error as? LocalizedError)?.errorDescription {
                        Text(errorDescription)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Loading Failed")
                            .foregroundStyle(.secondary)
                    }
                    
                    Button {
                        retryHandler()
                    } label: {
                        Text("Retry")
                    }
                    .foregroundStyle(Color.accentColor)
                }
                .font(.caption)
                .multilineTextAlignment(.center)
                Spacer()
            }
        }
    }
}

// MARK: - Model

enum LoadingState<Value> {
    case loading
    case failed(Error)
    case loaded(Value)
}

@MainActor
class AsyncLoader<Output>: ObservableObject {
    @Published var state: LoadingState<Output> = .loading
    let action: () async throws -> Output
    
    init(action: @escaping () async throws -> Output) {
        self.action = action
    }
    
    func load() async {
        do {
            state = .loading
            let output = try await action()
            self.state = .loaded(output)
        } catch {
            state = .failed(error)
        }
    }
}
