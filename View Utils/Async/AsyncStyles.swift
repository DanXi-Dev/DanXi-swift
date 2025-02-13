import SwiftUI

// MARK: - Async Content Style

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
    /// The default style used in full-page loader
    public static let paged = AsyncContentStyle {
        ProgressView {
            Text("Loading", bundle: .module)
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
    
    /// The loading style used for a part of a page
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

// MARK: - Async Collection Style

@MainActor
public struct AsyncCollectionStyle: Sendable {
    typealias AsyncLayout = (AnyView, AnyView) -> AnyView
    
    public init(layout: @MainActor @escaping @Sendable (AnyView, AnyView) -> some View, style: AsyncContentStyle = .collection) {
        self.layout = { AnyView(layout($0, $1)) }
        self.contentStyle = style
    }
    
    let layout: AsyncLayout
    let contentStyle: AsyncContentStyle
}

extension AsyncCollectionStyle {
    public static let plain = AsyncCollectionStyle { contents, footer in
        Group {
            contents
            footer
        }
    }
}

extension AsyncContentStyle {
    private struct LoadingView: View {
        @State private var isAnimating = false
        
        var body: some View {
            ActivityIndicatorView(isAnimating: isAnimating)
                .onAppear {
                    isAnimating = true
                }
                .onDisappear {
                    isAnimating = false
                }
        }
    }

    #if os(watchOS)

    private struct ActivityIndicatorView: View {
        let isAnimating: Bool
        
        var body: some View {
            ProgressView()
        }
    }

    #else

    private struct ActivityIndicatorView: UIViewRepresentable {
        let isAnimating: Bool
        
        func makeUIView(context: Context) -> UIActivityIndicatorView {
            let view = UIActivityIndicatorView()
            view.hidesWhenStopped = false
            return view
        }
        
        func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
            if isAnimating {
                uiView.startAnimating()
            } else {
                uiView.stopAnimating()
            }
        }
        
        static func dismantleUIView(_ uiView: UIActivityIndicatorView, coordinator: ()) {
            uiView.stopAnimating()
        }
    }

    #endif
    
    /// The loading style used for the footer of an ``AsyncCollection``
    public static let collection: AsyncContentStyle = AsyncContentStyle {
        HStack {
            Spacer()
            LoadingView()
            Spacer()
        }
        .frame(height: 50)
        .listRowBackground(Color.clear)
        #if !os(watchOS)
        .listRowSeparator(.hidden, edges: .bottom)
        #endif
    } errorView: { error, retry in
        HStack {
            Spacer()
            VStack {
                Text(error.localizedDescription)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                Button {
                    Task {
                        retry()
                    }
                } label: {
                    Text("Retry", bundle: .module)
                        .foregroundColor(.accentColor)
                }
            }
            .font(.caption)
            Spacer()
        }
        .frame(height: 50)
        .listRowBackground(Color.clear)
        #if !os(watchOS)
        .listRowSeparator(.hidden, edges: .bottom)
        #endif
    }
}
