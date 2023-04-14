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
            if DXModel.shared.isAdmin {
                TextField("Special Tag", text: $specialTag)
            }
            
            THContentEditor(content: $content)
        }
        .completed(!content.isEmpty)
        .scrollDismissesKeyboard(.immediately)
    }
}
