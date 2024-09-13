import SwiftUI


/// A view that presents an item that needs a loading process.
///
/// Use `AsyncContentView` for views that need relevent data to be loaded from disk
/// or network. The view presents a loading view during loading process, and displays
/// the designated view after the loading process is completed. In case there is an error,
/// the view displays an error view.
///
/// You may specify the styles of the loading view and error view by passing an ``AsyncContentStyle``.
public struct AsyncContentView<Value: Sendable, Content: View>: View {
    public typealias Loader = () async throws -> Value
    
    private let style: AsyncContentStyle
    private let animation: Animation?
    private let defaultAction: Loader
    private let refreshAction: Loader?
    private let contentView: (Value) -> Content
    
    @State private var phase: AsyncContentPhase<Value> = .idle
    
    
    /// Create an `AsyncContentView`.
    /// - Parameters:
    ///   - style: Specify the style of loading view and error view. Use preconfigured styles like `.paged` and `.widget`, or create your own.
    ///   - animation: The animation used during view transition.
    ///   - defaultAction: The loading process to load the data item.
    ///   - refreshAction: If provided, the view supports pull to refresh, and this closure will be called during refresh process.
    ///   - content: A closure specifying how to present the data item.
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


/// The style used in ``AsyncContentView``.
@MainActor
public struct AsyncContentStyle: Sendable {
    public typealias Retry = @Sendable () -> Void
    
    /// Create a style.
    /// - Parameters:
    ///   - loadingView: The loading view.
    ///   - errorView: Render the error view using an error and a retry action.
    public init(@ViewBuilder loadingView: @MainActor @escaping @Sendable () -> some View,
                @ViewBuilder errorView: @MainActor @escaping @Sendable (Error, @escaping Retry) -> some View) {
        self.loadingView = { () -> AnyView in AnyView(loadingView()) }
        self.errorView = { error, retry in AnyView(errorView(error, retry)) }
    }
    
    let loadingView: @MainActor @Sendable () -> AnyView
    let errorView: @MainActor @Sendable (Error, @escaping Retry) -> AnyView
}

extension AsyncContentStyle {
    public static let paged = AsyncContentStyle {
        VStack {
            ProgressView()
            Text("Loading", bundle: .module)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    } errorView: { error, retry in
        VStack {
            Text("Loading Failed", bundle: .module)
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
                Text("Retry", bundle: .module)
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
                    Text("Loading Failed", bundle: .module)
                        .foregroundStyle(.secondary)
                }
                
                Button {
                    retry()
                } label: {
                    Text("Retry", bundle: .module)
                }
                .foregroundStyle(Color.accentColor)
            }
            .font(.caption)
            .multilineTextAlignment(.center)
            Spacer()
        }
    }
}
