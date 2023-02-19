import SwiftUI

struct LoadingFooter: View {
    @Binding var loading: Bool
    let errorDescription: String
    let action: () async -> Void
    
    var body: some View {
        if loading {
            loadingView
        } else {
            failedView
        }
    }
    
    var failedView: some View {
        HStack {
            Spacer()
            VStack {
                Text(errorDescription)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                Button(LocalizedStringKey("Retry")) {
                    Task {
                        await action()
                    }
                }
            }
            .font(.caption)
            Spacer()
        }
    }
    
    var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }
    
    var retryView: some View {
        HStack {
            Spacer()
            Button("Load More") {
                Task {
                    await action()
                }
            }
                .font(.caption)
            Spacer()
        }
    }
}

struct LoadingFooter_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoadingFooter(loading: .constant(false),
                            errorDescription: "Requested resourse not found") {
                // do something
            }
            
            LoadingFooter(loading: .constant(false),
                            errorDescription: "Requested resourse not found") {
                // do something
            }
                            .preferredColorScheme(.dark)
            
            LoadingFooter(loading: .constant(true),
                            errorDescription: "Requested resourse not found") {
                // do something
            }
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
