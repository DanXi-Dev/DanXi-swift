import SwiftUI

public struct AsyncContentView<Value, Content: View>: View {
    public typealias Loader = () async throws -> Value
    
    private let style: AsyncContentStyle
    private let animation: Animation?
    private let defaultAction: Loader
    private let refreshAction: Loader?
    private let contentView: (Value) -> Content
    
    @State private var phase: AsyncContentPhase<Value> = .idle
    
    public init(style: AsyncContentStyle = .paged,
                animation: Animation? = nil,
                defaultAction: @escaping Loader,
                refreshAction: Loader? = nil,
                @ViewBuilder content: @escaping (Value) -> Content) {
        self.style = style
        self.animation = animation
        self.defaultAction = defaultAction
        self.refreshAction = refreshAction
        self.contentView = content
    }
    
    private func load() async {
        do {
            phase = .loading
            let value = try await defaultAction()
            
            withAnimation(animation) {
                phase = .completed(value: value)
            }
        } catch _ as CancellationError {
            phase = .idle
        } catch {
            withAnimation(animation) {
                phase = .failed(error: error)
            }
        }
    }
    
    private func refresh() async throws {
        guard let refreshAction else { return }
        let value = try await refreshAction()
        phase = .completed(value: value)
    }
    
    public var body: some View {
        switch phase {
        case .idle:
            style.loadingView()
                .onAppear {
                    Task.detached {
                        await load()
                    }
                }
        case .loading:
            style.loadingView()
        case .completed(let value):
            if refreshAction != nil {
                contentView(value)
                    .refreshable {
                        try? await refresh()
                    }
            } else {
                contentView(value)
            }
        case .failed(let error):
            style.errorView(error) {
                Task.detached {
                    await load()
                }
            }
        }
    }
}

enum AsyncContentPhase<Value> {
    case idle
    case loading
    case completed(value: Value)
    case failed(error: Error)
}

public struct AsyncContentStyle {
    public typealias Retry = () -> Void
    
    public init(@ViewBuilder loadingView: @escaping () -> some View,
                @ViewBuilder errorView: @escaping (Error, @escaping Retry) -> some View) {
        self.loadingView = { () -> AnyView in AnyView(loadingView()) }
        self.errorView = { error, retry in AnyView(errorView(error, retry)) }
    }
    
    let loadingView: () -> AnyView
    let errorView: (Error, @escaping Retry) -> AnyView
}

extension AsyncContentStyle {
    public static let paged = AsyncContentStyle {
        VStack {
            ProgressView()
            Text("Loading")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    } errorView: { error, retry in
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
                retry()
            } label: {
                Text("Retry")
            }
            .foregroundStyle(Color.accentColor)
        }
        .padding()
    }
    
    public static let widget = AsyncContentStyle {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .listRowBackground(Color.clear)
    } errorView: { error, retry in
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
                    retry()
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
