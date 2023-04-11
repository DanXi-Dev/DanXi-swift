import SwiftUI

struct THFloorEditSheet: View {
    @EnvironmentObject var model: THFloorModel
    @State var content: String
    @State var specialTag = ""
    
    init(_ content: String) {
        self._content = State(initialValue: content)
    }
    
    var body: some View {
        Sheet("Edit Reply") {
            try await model.edit(content, specialTag: specialTag)
        } content: {
            Section {
                if DXModel.shared.isAdmin {
                    TextField("Special Tag", text: $specialTag)
                }
                TextEditView($content,
                             placeholder: "Enter reply content")
            } header: {
                Text("TH Edit Alert")
            }
            .textCase(nil)
            
            
            if !content.isEmpty {
                Section {
                    THFloorContent(content, interactable: false)
                } header: {
                    Text("Preview")
                }
            }
        }
        .completed(!content.isEmpty)
    }
}
