import SwiftUI

struct ListLoadingView: View {
    @Binding var loading: Bool
    let errorDescription: LocalizedStringKey
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
                    .foregroundColor(.secondary)
                Button("Retry") {
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
}

struct ListLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ListLoadingView(loading: .constant(false),
                            errorDescription: "Requested resourse not found") {
                // do something
            }
            ListLoadingView(loading: .constant(false),
                            errorDescription: "Requested resourse not found") {
                // do something
            }
                            .preferredColorScheme(.dark)
            
            ListLoadingView(loading: .constant(true),
                            errorDescription: "Requested resourse not found") {
                // do something
            }
        }
        .previewLayout(.sizeThatFits)
        .padding()
        
        
        
    }
}
