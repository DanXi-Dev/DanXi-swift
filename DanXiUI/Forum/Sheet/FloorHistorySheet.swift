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
            AsyncContentView {
                let punishments = try await ForumAPI.listFloorPunishmentStatus(id: floorId)
                let histories = try await ForumAPI.listFloorHistory(id: floorId)
                let information = AdministritiveInformation(punishments: punishments, histories: histories)
                return information
            } content: { (information: AdministritiveInformation) in
                List {
                    PunishmentView(punishments: information.punishments)
                    
                    if !information.histories.isEmpty {
                        Section {
                            ForEach(information.histories) { history in
                                HistorySheetItem(history: history)
                            }
                        } header: {
                            Text("Edit History", bundle: .module)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Done", bundle: .module)
                        }
                    }
                }
                .navigationTitle(String(localized: "Administrative Info", bundle: .module))
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
            Section {
                ForEach(entries) { entry in
                    LabeledContent(entry.division, value: entry.date, format: .dateTime)
                }
            } header: {
                Text("Punishment Status", bundle: .module)
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
                Text("Edit reason: \(history.reason)", bundle: .module)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            
            // TODO: sensitive
            
            CustomMarkdown(MarkdownContent(history.content))
                .foregroundColor(.primary)
            
            HStack {
                Text(history.timeUpdated.formatted())
                Spacer()
                Text("User: \(String(history.userId))", bundle: .module)
            }
            .foregroundColor(.secondary)
            .font(.caption)
        }
        .alert(String(localized: "Restore History", bundle: .module), isPresented: $showAlert) {
            TextField(String(localized: "Restore reason", bundle: .module), text: $restoreReason)
            AsyncButton {
                try await model.restoreFloor(floorId: history.floorId, historyId: history.id, reason: restoreReason)
            } label: {
                Text("Submit", bundle: .module)
            }
            Button(role: .cancel) {
                
            } label: {
                Text("Cancel", bundle: .module)
            }
        }
        .swipeActions {
            Button {
                showAlert = true
            } label: {
                Label(String(localized: "Restore", bundle: .module), systemImage: "arrow.uturn.backward")
            }
            
            Button {
                UIPasteboard.general.string = history.content
            } label: {
                Label(String(localized: "Copy Full Text", bundle: .module), systemImage: "doc.on.doc")
            }
            .tint(.yellow)
        }
    }
}
