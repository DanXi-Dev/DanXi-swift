import SwiftUI

struct THDeleteSheet: View {
    @Binding var floor: THFloor
    @State var deleteReason = ""
    @State var addBan = false
    @State var penaltyLevel = 1
    
    var body: some View {
        FormPrimitive(title: "Delete Post",
                      allowSubmit: true,
                      needConfirmation: true) {
            Section {
                ScrollView(.vertical, showsIndicators: false) {
                    ReferenceView(floor.content,
                                  mentions: floor.mention)
                    .interactable(false)
                }
                .frame(maxHeight: 200)
            } header: {
                Label("Content to Delete", systemImage: "text.alignleft")
            }
            
            Section {
                TextField("Enter delete reason", text: $deleteReason)
            }
            
            Section {
                Toggle(isOn: $addBan.animation()) {
                    Label("Add Ban", systemImage: "nosign")
                }
                
                if addBan {
                    Stepper(value: $penaltyLevel, in: 1...3) {
                        Label("Penalty Level: \(penaltyLevel)", systemImage: "chevron.up.chevron.down")
                    }
                }
            }
        } action: {
            floor = try await TreeholeRequests.deleteFloor(floorId: floor.id, reason: deleteReason)
            
            if addBan {
                let hole = try await TreeholeRequests.loadHoleById(holeId: floor.holeId)
                let divisionId = hole.divisionId
                print(divisionId)
                // TODO: add ban
            }
        }
    }
}

struct THDeleteSheet_Previews: PreviewProvider {
    static var previews: some View {
        THDeleteSheet(floor: .constant(Bundle.main.decodeData("long-floor")))
    }
}
