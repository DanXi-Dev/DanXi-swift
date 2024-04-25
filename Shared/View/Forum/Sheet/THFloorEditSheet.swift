import SwiftUI

struct THFloorEditSheet: View {
    @ObservedObject private var appModel = DXModel.shared
    @EnvironmentObject private var model: THFloorModel
    @State private var content: String
    @State private var runningImageUploadTask = 0
    @State private var specialTag = ""
    @State private var foldReason = ""
    
    init(_ content: String) {
        self._content = State(initialValue: content)
    }
    
    var body: some View {
        Sheet("Edit Reply") {
            try await model.edit(content, specialTag: specialTag, fold: foldReason)
        } content: {
            if appModel.isAdmin {
                Section("Admin Actions") {
                    TextField("Special Tag", text: $specialTag)
                    TextField("Fold Reason", text: $foldReason)
                }
            }
            
            THContentEditor(content: $content, runningImageUploadTasks: $runningImageUploadTask, initiallyFocused: !appModel.isAdmin)
        }
        .completed(!content.isEmpty && runningImageUploadTask <= 0)
        .warnDiscard(!content.isEmpty || runningImageUploadTask > 0)
        .scrollDismissesKeyboard(.immediately)
    }
}
