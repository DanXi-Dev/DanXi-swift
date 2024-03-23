import SwiftUI

struct THHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: THFloorModel
    @State private var histories: [THHistory] = []
    
    var body: some View {
        NavigationView {
            Form {
                AsyncContentView {
                    return try await model.loadHistory()
                } content: { histories in
                    List {
                        ForEach(histories) { history in
                            THHistorySheetItem(history: history)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
            .navigationTitle("Edit History")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.visible)
        }
    }
}

struct THHistorySheetItem: View {
    @EnvironmentObject private var model: THFloorModel
    let history: THHistory
    
    @State private var showAlert = false
    @State private var restoreReason = ""
    
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
            
            Button {
                UIPasteboard.general.string = history.content
            } label: {
                Label("Copy Full Text", systemImage: "doc.on.doc")
            }
            .tint(.yellow)
        }
    }
}
