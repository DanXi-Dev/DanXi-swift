import SwiftUI

struct LoadingView<Content: View>: View {
    @Binding var loading: Bool
    @Binding var finished: Bool
    let errorDescription: LocalizedStringKey
    let content: Content
    
    let action: () async -> Void
    
    init(loading: Binding<Bool>,
         finished: Binding<Bool>,
         errorDescription: LocalizedStringKey,
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
                            errorDescription: "Requested resourse not found") {
                // initialization code
            } content: {
                EmptyView()
            }

            LoadingView(loading: .constant(false),
                            finished: .constant(false),
                            errorDescription: "Requested resourse not found") {
                // initialization code
            } content: {
                EmptyView()
            }
            .preferredColorScheme(.dark)

            LoadingView(loading: .constant(true),
                            finished: .constant(false),
                            errorDescription: "") {
                // initialization code
            } content: {
                EmptyView()
            }
        }
    }
}
