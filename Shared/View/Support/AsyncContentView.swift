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
    
    var body: some View {
        nestedView
    }
}

struct AsyncTaskView<Content: View>: View {
    private let style: AsyncContentStyle
    @StateObject private var loader: AsyncLoader<Void>
    private let content: Content
    
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
    }
    
    var body: some View {
        switch loader.state {
        case .loading:
            LoadingView(style: self.style)
                .task {
                    await loader.load()
                }
        case .failed(let error):
            ErrorView(style: self.style, error: error) {
                loader.state = .loading
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
    
    init(style: AsyncContentStyle = .page,
         action: @escaping () async throws -> Output,
         @ViewBuilder content: @escaping (Output) -> Content) {
        self.style = style
        self._loader = StateObject(wrappedValue: AsyncLoader(action: action))
        self.content = content
    }

    var body: some View {
        switch loader.state {
        case .loading:
            LoadingView(style: self.style)
                .task {
                    await loader.load()
                }
        case .failed(let error):
            ErrorView(style: self.style, error: error) {
                loader.state = .loading
            }
        case .loaded(let output):
            content(output)
        }
    }
}

fileprivate struct LoadingView: View {
    let style: AsyncContentStyle
    
    var body: some View {
        if style == .page {
            VStack {
                ProgressView()
                Text("Loading")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } else {
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
        if style == .page {
            VStack {
                Text("Loading Failed")
                    .font(.title)
                    .fontWeight(.bold)
                
                if let errorDescription = (error as? LocalizedError)?.errorDescription {
                    Text(errorDescription)
                        .font(.callout)
                        .padding(.bottom)
                        .multilineTextAlignment(.center)
                }
                
                Button {
                    retryHandler()
                } label: {
                    Text("Retry")
                }
                .frame(width: 120, height: 25)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.secondary, lineWidth: 1)
                )
            }
            .padding()
            .foregroundColor(.secondary)
        } else {
            HStack {
                Spacer()
                VStack {
                    if let errorDescription = (error as? LocalizedError)?.errorDescription {
                        Text(errorDescription)
                    } else {
                        Text("Loading Failed")
                    }
                    
                    Button {
                        retryHandler()
                    } label: {
                        Text("Retry")
                    }
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
