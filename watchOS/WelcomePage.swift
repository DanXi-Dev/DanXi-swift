import SwiftUI
import FudanUI
import FudanKit
import ViewUtils

struct WatchWelcomePage: View {
    @ObservedObject private var campusModel = CampusModel.shared
    @ObservedObject private var syncronizer = CredentialSynchronizer.shared
    @Binding private var showLoginSheet: Bool
    private let syncOperation: () async throws -> Void
    
    init(showLoginSheet: Binding<Bool>, syncOperation: @escaping () async throws -> Void) {
        self._showLoginSheet = showLoginSheet
        self.syncOperation = syncOperation
    }
    
    var body: some View {
        ScrollView {
            VStack {
                Image(systemName: "person.badge.shield.exclamationmark")
                    .font(.largeTitle)
                Text("Not Logged in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 10)
            
            AsyncButton {
                try await syncOperation()
            } label: {
                Text("Sync From iPhone")
                    .font(.caption)
            }
            .tint(.blue)
            .disabled(!syncronizer.activated)
            
            Button {
                showLoginSheet = true
            } label: {
                Text("Manual Log In")
            }
        }
    }
}

#Preview {
    @Previewable @State var showLoginSheet = false
    
    WatchWelcomePage(showLoginSheet: $showLoginSheet) {
        try await Task.sleep(for: .seconds(1))
    }
    .sheet(isPresented: $showLoginSheet) {
        LoginSheet()
    }
}
