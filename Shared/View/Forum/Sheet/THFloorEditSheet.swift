import SwiftUI

struct THFloorEditSheet: View {
    @EnvironmentObject var model: THFloorModel
    @State var content: String
    @State var specialTag = ""
    
    init(_ content: String) {
        self._content = State(initialValue: content)
    }
    
    var body: some View {
        FormPrimitive(title: "Edit Reply",
                      allowSubmit: !content.isEmpty,
                      errorTitle: "Edit Reply Failed") {
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
                    THFloorContent(content)
                } header: {
                    Text("Preview")
                }
            }
        } action: {
            try await model.edit(content, specialTag: specialTag)
        }
    }
}
