import SwiftUI
import ViewUtils
import DanXiKit
import MarkdownUI

struct FloorHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    let floorId: Int
    
    var body: some View {
        NavigationStack {
            AsyncContentView { _ in
                return try await ForumAPI.listFloorHistory(id: floorId)
            } content: { histories in
                List {
                    ForEach(histories) { history in
                        HistorySheetItem(history: history)
                    }
                }
                .listStyle(.insetGrouped)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                        }
                    }
                }
                .navigationTitle("Administrative Info")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct HistorySheetItem: View {
    @EnvironmentObject private var model: HoleModel
    let history: FloorHistory
    
    @State private var showAlert = false
    @State private var restoreReason = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !history.reason.isEmpty {
                Text("Edit reason: \(history.reason)")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            
            // TODO: sensitive
            
            CustomMarkdown(MarkdownContent(history.content))
                .foregroundColor(.primary)
            
            HStack {
                Text(history.timeUpdated.formatted())
                Spacer()
                Text("User: \(String(history.userId))")
            }
            .foregroundColor(.secondary)
            .font(.caption)
        }
        .alert("Restore History", isPresented: $showAlert) {
            TextField("Restore reason", text: $restoreReason)
            AsyncButton {
                try await model.restoreFloor(floorId: history.floorId, historyId: history.id, reason: restoreReason)
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
