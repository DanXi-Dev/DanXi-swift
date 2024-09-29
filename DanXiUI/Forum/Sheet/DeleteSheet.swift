import SwiftUI
import ViewUtils
import DanXiKit

struct DeleteSheet: View {
    @EnvironmentObject private var model: HoleModel
    
    let presentation: FloorPresentation
    @State private var reason = ""
    @State private var ban = false
    @State private var days = 1
    
    private var floorId: Int {
        presentation.floor.id
    }
    
    var body: some View {
        Sheet(String(localized: "Delete Post", bundle: .module)) {
            let banDays = ban ? days : 0
            try await model.punish(floorId: floorId, reason: reason, days: banDays)
        } content: {
            Section {
                ScrollView(.vertical, showsIndicators: false) {
                    ForumContentPreview(sections: presentation.sections)
                        // to fix the top padding caused by ScrollView position
                        .padding(.top, 7)
                }
                .frame(maxHeight: 200)
            } header: {
                Label(String(localized: "Content to Delete", bundle: .module), systemImage: "text.alignleft")
            }
            .labelStyle(.titleOnly)
            
            Section {
                TextField(String(localized: "Enter delete reason", bundle: .module), text: $reason)
            }
            
            Section {
                Toggle(isOn: $ban.animation()) {
                    Label(String(localized: "Add Ban", bundle: .module), systemImage: "nosign")
                }
                
                if ban {
                    Stepper(value: $days, in: 1...3600) {
                        Label(String(localized: "Penalty Duration: \(days)", bundle: .module), systemImage: "chevron.up.chevron.down")
                    }
                    
                    NavigationLink {
                        PunishmentHistory(floorId: floorId)
                    } label: {
                        Label(String(localized: "Punishment History", bundle: .module), systemImage: "person.badge.clock")
                    }
                }
            }
            .labelStyle(.titleOnly)
            
            if ban {
                PunishmentNotice(floorId: floorId)
            }
            
        }
        .watermark()
    }
}

private struct PunishmentNotice: View {
    let floorId: Int
    @State private var history: [String]?
    
    private var permanentBan: Bool {
        if let history {
            !history.filter({ $0.contains("永久封禁") }).isEmpty
        } else {
            false
        }
    }
    
    private var multipleOffence: Bool {
        if let history {
            history.count >= 7
        } else {
            false
        }
    }
    
    var body: some View {
        Section {
            if permanentBan {
                Label(String(localized: "This user has been warned with permenant ban notice", bundle: .module), systemImage: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                
            } else if multipleOffence {
                Label(String(localized: "This user has multiple offence record", bundle: .module), systemImage: "exclamationmark.circle.fill")
                    .foregroundColor(.yellow)
            } else {
                // This is equivalent as EmptyView, but to trigger `task` modifier. Othewise it won't be executed.
                Text(verbatim: "").listRowBackground(Color.clear)
            }
        }
        .task {
            guard history == nil else { return }
            
            let history = try? await ForumAPI.listFloorPunishmentHistory(id: floorId)
            withAnimation {
                self.history = history
            }
        }
    }
}

private struct PunishmentHistory: View {
    let floorId: Int
    
    var body: some View {
        AsyncContentView {
            try await ForumAPI.listFloorPunishmentHistory(id: floorId)
        } content: { histories in
            List(Array(histories.enumerated()), id: \.offset) { _, history in
                Text(history)
            }
            .listStyle(.insetGrouped)
            .navigationTitle(String(localized: "Punishment History", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
