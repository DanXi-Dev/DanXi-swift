import SwiftUI

struct THDeleteSheet: View {
    @EnvironmentObject private var model: THFloorModel
    
    @State private var reason = ""
    @State private var ban = false
    @State private var days = 1
    
    var body: some View {
        Sheet("Delete Post") {
            try await model.punish(reason, days: ban ? days : 0)
        } content: {
            Section {
                ScrollView(.vertical, showsIndicators: false) {
                    THFloorContent(model.floor.content)
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
                        THPunishmentHistorySheet()
                    } label: {
                        Label("Punishment History", systemImage: "person.badge.clock")
                    }
                }
            }
            .labelStyle(.titleOnly)
            
            if ban {
                PunishmentNotice()
            }
        }
        .warnDiscard(!reason.isEmpty)
    }
}

fileprivate struct PunishmentNotice: View {
    @EnvironmentObject private var model: THFloorModel
    @State private var loaded = false
    @State private var multipleOffence = false
    @State private var permanentBan = false
    
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
            guard !loaded else {
                return
            }
            
            do {
                let history = try await THRequests.loadPunishmenthistory(model.floor.id)
                withAnimation {
                    multipleOffence = history.count >= 7
                    permanentBan = !history.filter({ $0.contains("永久封禁") }).isEmpty
                }
            } catch {
                
            }
        }
    }
}

struct THPunishmentHistorySheet: View {
    @EnvironmentObject private var model: THFloorModel
    
    var body: some View {
        AsyncContentView {
            return try await THRequests.loadPunishmenthistory(model.floor.id)
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
