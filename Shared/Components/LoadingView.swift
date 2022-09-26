import SwiftUI


/// A page that need to be initialized before presented to user.
///
/// This page will display a loading info when loading, and a retry button when loading fails. After the initial loading is complete, the content will be presented.
/// Usage:
/// ```
/// LoadingView(loading: $loading,
///             finished: $initFinished,
///             errorDescription: initError,
///             action: initialLoad) {
///     DetailPage()
/// }
/// ```
struct LoadingView<Content: View>: View {
    @Binding var loading: Bool
    @Binding var finished: Bool
    let errorDescription: String
    let content: Content
    
    let action: () async -> Void
    
    
    /// Create a loading view.
    /// - Parameters:
    ///   - loading: A boolean binding representing the loading status.
    ///   - finished: Determine if the content is ready to be presented.
    ///   - errorDescription: The description to be displayed when loading fails.
    ///   - action: The loading function.
    ///   - content: Content to be displayed when loading is done.
    init(loading: Binding<Bool>,
         finished: Binding<Bool>,
         errorDescription: String,
         action: @escaping () async -> Void,
         @ViewBuilder content: () -> Content) {
        _loading = loading
        _finished = finished
        self.errorDescription = errorDescription
        self.action = action
        self.content = content()
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
            loading = true
            defer { loading = false }
            await action()
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
            
            Button("Retry") {
                Task { @MainActor in
                    loading = true
                    defer { loading = false }
                    await action()
                }
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



struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoadingView(loading: .constant(false),
                            finished: .constant(false),
                            errorDescription: NSLocalizedString("Requested resourse not found", comment: "")) {
                // initialization code
            } content: {
                EmptyView()
            }
            .previewDisplayName("Failed")

            LoadingView(loading: .constant(true),
                            finished: .constant(false),
                            errorDescription: "") {
                // initialization code
            } content: {
                EmptyView()
            }
            .previewDisplayName("Loading")
        }
    }
}
