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
        Sheet("Delete Post") {
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
                Label("Content to Delete", systemImage: "text.alignleft")
            }
            .labelStyle(.titleOnly)
            
            Section {
                TextField("Enter delete reason", text: $reason)
            }
            
            Section {
                Toggle(isOn: $ban.animation()) {
                    Label("Add Ban", systemImage: "nosign")
                }
                
                if ban {
                    Stepper(value: $days, in: 1...3600) {
                        Label("Penalty Duration: \(days)", systemImage: "chevron.up.chevron.down")
                    }
                    
                    NavigationLink {
                        PunishmentHistory(floorId: floorId)
                    } label: {
                        Label("Punishment History", systemImage: "person.badge.clock")
                    }
                }
            }
            .labelStyle(.titleOnly)
            
            if ban {
                PunishmentNotice(floorId: floorId)
            }
            
        }
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
                Label("This user has been warned with permenant ban notice", systemImage: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                
            } else if multipleOffence {
                Label("This user has multiple offence record", systemImage: "exclamationmark.circle.fill")
                    .foregroundColor(.yellow)
            } else {
                // This is equivalent as EmptyView, but to trigger `task` modifier. Othewise it won't be executed.
                Text("").listRowBackground(Color.clear)
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
            .navigationTitle("Punishment History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
