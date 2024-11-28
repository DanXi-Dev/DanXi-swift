#if os(watchOS)
import SwiftUI

public struct WatchWelcomePage: View {
    @Binding private var showLoginSheet: Bool
    
    public init(showLoginSheet: Binding<Bool>) {
        self._showLoginSheet = showLoginSheet
    }
    
    public var body: some View {
        ScrollView {
            VStack {
                Image(systemName: "person.badge.shield.exclamationmark")
                    .font(.largeTitle)
                Text("Not Logged in", bundle: .module)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 10)
            
            Button {
                // TODO: Sync from iPhone
            } label: {
                Text("Sync From iPhone", bundle: .module)
                    .font(.caption)
            }
            .tint(.blue)
            .disabled(true) // TODO: remove this after watch connectivity is finished
            
            Button {
                showLoginSheet = true
            } label: {
                Text("Manual Log In", bundle: .module)
            }
        }
    }
}

#Preview {
    @Previewable @State var showLoginSheet = false
    
    WatchWelcomePage(showLoginSheet: $showLoginSheet)
        .sheet(isPresented: $showLoginSheet) {
            LoginSheet()
        }
}

#endif

