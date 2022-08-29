import SwiftUI

struct InitLoadingView<Content: View>: View {
    @Binding var loading: Bool
    @Binding var failed: Bool
    let errorDescription: LocalizedStringKey
    let content: Content
    
    let action: () async -> Void
    
    init(loading: Binding<Bool>,
         failed: Binding<Bool>,
         errorDescription: LocalizedStringKey,
         action: @escaping () async -> Void,
         @ViewBuilder content: () -> Content) {
        _loading = loading
        _failed = failed
        self.errorDescription = errorDescription
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        if loading {
            loadingView
        } else if failed {
            failedView
        } else {
            content
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
            defer {
                loading = false
            }
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
            
            Button("Retry") {
                Task { @MainActor in
                    loading = true
                    failed = false
                    await action()
                }
            }
            .frame(width: 120, height: 25)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.secondary, lineWidth: 1)
            )
        }
        .foregroundColor(.secondary)
    }
}

struct InitLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            InitLoadingView(loading: .constant(false),
                            failed: .constant(true),
                            errorDescription: "Network error, try again later") {
                // initialization code
            } content: {
                EmptyView()
            }
            
            InitLoadingView(loading: .constant(false),
                            failed: .constant(true),
                            errorDescription: "Network error, try again later") {
                // initialization code
            } content: {
                EmptyView()
            }
            .preferredColorScheme(.dark)
            
            InitLoadingView(loading: .constant(true),
                            failed: .constant(true),
                            errorDescription: "") {
                // initialization code
            } content: {
                EmptyView()
            }
        }
    }
}
