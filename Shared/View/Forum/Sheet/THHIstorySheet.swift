import SwiftUI

struct THHistorySheet: View {
    @EnvironmentObject var model: THFloorModel
    @State var histories: [THHistory] = []
    
    var body: some View {
        NavigationView {
            LoadingPage {
                self.histories = try await model.loadHistory()
            } content: {
                List {
                    ForEach(histories) { history in
                        THHistorySheetItem(history: history)
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Edit History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct THHistorySheetItem: View {
    @EnvironmentObject var model: THFloorModel
    let history: THHistory
    
    @State var showAlert = false
    @State var restoreReason = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !history.reason.isEmpty {
                Text("Edit reason: \(history.reason)")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            
            MarkdownView(history.content)
                .foregroundColor(.primary)
            
            HStack {
                Text(history.updateTime.formatted())
                Spacer()
                Text("User: \(String(history.userId))")
            }
            .foregroundColor(.secondary)
            .font(.caption)
        }
        .alert("Restore History", isPresented: $showAlert) {
            TextField("Restore reason", text: $restoreReason)
            AsyncButton {
                try await model.restore(history.id, reason: restoreReason)
            } label: {
                Text("Submit")
            }
            Button("Cancel", role: .cancel) { }
        }
        .swipeActions {
            Button {
                showAlert = true
            } label: {
                Label("Restore", systemImage: "arrow.uturn.backward")
            }
        }
    }
}
