import SwiftUI

struct EditReplyPage: View {
    @Binding var floor: THFloor // replace original floor after edit succeeded
    @State var content: String
    let floors: [THFloor]
    
    init(floor: Binding<THFloor>,
         content: String = "",
         floors: [THFloor] = []) {
        self._floor = floor
        self._content = State(initialValue: content)
        self.floors = floors
    }
    
    var body: some View {
        PrimitiveForm(title: "Edit Reply",
                      allowSubmit: !content.isEmpty,
                      errorTitle: "Edit Reply Failed") {
            Section {
                TextEditView($content,
                             placeholder: "Enter reply content")
            } header: {
                Text("TH Edit Alert")
            }
            .textCase(nil)
            
            if !content.isEmpty {
                Section {
                    ReferenceView(content, floors: floors)
                        .padding(.vertical, 5)
                } header: {
                    Text("Preview")
                }
            }
        } action: {
            floor = try await NetworkRequests.shared.editReply(content: content, floorId: floor.id)
        }
    }
}

struct EditReplyPage_Previews: PreviewProvider {
    static var previews: some View {
        EditReplyPage(floor: .constant(PreviewDecode.decodeObj(name: "floor")!))
    }
}
