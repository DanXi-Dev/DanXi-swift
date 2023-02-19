import SwiftUI


struct LoadingPage<Content: View>: View {
    @State var loading = true
    @State var finished: Bool
    @State var errorDescription = ""
    let content: Content
    let action: () async throws -> Void
    
    
    init(finished: Bool = false,
         action: @escaping () async throws -> Void,
         @ViewBuilder content: () -> Content) {
        self._finished = State(initialValue: finished)
        self.action = action
        self.content = content()
    }
    
    func load() async {
        do {
            defer { loading = false }
            try await action()
            finished = true
        } catch {
            errorDescription = error.localizedDescription
        }
    }
    
    var body: some View {
        if finished {
            content
        } else if loading {
            loadingView
        } else {
            failedView
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("Loading")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .task { @MainActor in
            await load()
        }
    }
    
    private var failedView: some View {
        VStack {
            Text("Loading Failed")
                .font(.title)
                .fontWeight(.bold)
            
            Text(errorDescription)
                .font(.callout)
                .padding(.bottom)
                .multilineTextAlignment(.center)
            
            Button(LocalizedStringKey("Retry")) {
                loading = true
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



struct LoadingPage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoadingPage(finished: false) {
                // initialization code
            } content: {
                EmptyView()
            }
            .previewDisplayName("Loading")

            LoadingPage(finished: false) {
                throw NetworkError.invalidResponse
            } content: {
                EmptyView()
            }
            .previewDisplayName("Failed")
        }
    }
}
