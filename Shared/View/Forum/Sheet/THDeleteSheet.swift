import SwiftUI

struct THDeleteSheet: View {
    @EnvironmentObject var model: THFloorModel
    
    @State var reason = ""
    @State var ban = false
    @State var days = 1
    
    var body: some View {
        FormPrimitive(title: "Delete Post",
                      allowSubmit: true,
                      needConfirmation: true) {
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
                }
            }
        } action: {
            try await model.punish(reason, days: ban ? days : 0)
        }
    }
}
