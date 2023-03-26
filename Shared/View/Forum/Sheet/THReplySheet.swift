import SwiftUI

struct THReplySheet: View {
    @EnvironmentObject var model: THHoleModel
    @State var content: String
    
    init(_ content: String = "") {
        self._content = State(initialValue: content)
    }
    
    var body: some View {
        FormPrimitive(title: "Reply", allowSubmit: !content.isEmpty) {
            Section {
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
        } action: {
            try await model.reply(content)
        }
    }
}
