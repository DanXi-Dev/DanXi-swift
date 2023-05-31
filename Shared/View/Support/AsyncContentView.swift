import SwiftUI

// MARK: - View

enum AsyncContentStyle {
    case page, widget
}

struct AsyncContentView<Output, Content: View>: View {
    let style: AsyncContentStyle
    @StateObject var loader: AsyncLoader<Output>
    var content: (Output) -> Content
    
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
