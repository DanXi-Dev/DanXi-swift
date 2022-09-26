import SwiftUI

struct DeleteForm: View {
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
                        Label("Penalty Level: \(penaltyLevel)", systemImage: "exclamationmark.triangle")
                    }
                }
            }
        } action: {
            floor = try await DXNetworks.shared.deleteFloor(floorId: floor.id, reason: deleteReason)
            
            if addBan {
                let hole = try await DXNetworks.shared.loadHoleById(holeId: floor.holeId)
                let divisionId = hole.divisionId
                print(divisionId)
                // TODO: add ban
            }
        }
    }
}

struct DeleteForm_Previews: PreviewProvider {
    static var previews: some View {
        DeleteForm(floor: .constant(PreviewDecode.decodeObj(name: "long-floor")!))
    }
}
