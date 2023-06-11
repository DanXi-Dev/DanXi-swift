import SwiftUI

struct THDeleteSheet: View {
    @EnvironmentObject var model: THFloorModel
    
    @State var reason = ""
    @State var ban = false
    @State var days = 1
    
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
