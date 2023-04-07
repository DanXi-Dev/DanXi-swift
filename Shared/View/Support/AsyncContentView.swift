import SwiftUI

// MARK: - View

struct AsyncContentView<Output, Content: View>: View {
    @StateObject var loader: AsyncLoader<Output>
    var content: (Output) -> Content
    
    init(action: @escaping () async throws -> Output,
         @ViewBuilder content: @escaping (Output) -> Content) {
        self._loader = StateObject(wrappedValue: AsyncLoader(action: action))
        self.content = content
    }

    var body: some View {
        switch loader.state {
        case .loading:
            LoadingView()
                .task {
                    await loader.load()
                }
        case .failed(let error):
            ErrorView(error: error) {
                loader.state = .loading
            }
        case .loaded(let output):
            content(output)
        }
    }
}

fileprivate struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Loading")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

fileprivate struct ErrorView: View {
    let error: Error
    let retryHandler: () -> Void
    
    init(error: Error, retryHandler: @escaping () -> Void) {
        self.error = error
        self.retryHandler = retryHandler
    }
    
    var body: some View {
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
