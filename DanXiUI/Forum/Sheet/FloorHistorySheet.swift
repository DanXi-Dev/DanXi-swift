import SwiftUI
import ViewUtils
import DanXiKit
import MarkdownUI

struct FloorHistorySheet: View {
    struct AdministritiveInformation {
        let punishments: [Int: Date]
        let histories: [FloorHistory]
    }
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var divisionStore = DivisionStore.shared
    let floorId: Int
    
    var body: some View {
        NavigationStack {
            AsyncContentView { _ in
                let punishments = try await ForumAPI.listFloorPunishmentStatus(id: floorId)
                let histories = try await ForumAPI.listFloorHistory(id: floorId)
                let information = AdministritiveInformation(punishments: punishments, histories: histories)
                return information
            } content: { (information: AdministritiveInformation) in
                List {
                    PunishmentView(punishments: information.punishments)
                    
                    if !information.histories.isEmpty {
                        Section("Edit History") {
                            ForEach(information.histories) { history in
                                HistorySheetItem(history: history)
                            }
                        }
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

private struct PunishmentView: View {
    private let entries: [Entry]
    
    struct Entry: Identifiable {
        let id = UUID()
        let division: String
        let date: Date
    }
    
    init(punishments: [Int: Date]) {
        entries = DivisionStore.shared.divisions.compactMap { division in
            if let date = punishments[division.id] {
                Entry(division: division.name, date: date)
            } else {
                nil
            }
        }
    }
    
    var body: some View {
        if !entries.isEmpty {
            Section("Punishment Status") {
                ForEach(entries) { entry in
                    LabeledContent(entry.division, value: entry.date, format: .dateTime)
                }
            }
        }
    }
}

private struct HistorySheetItem: View {
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
