import SwiftUI
import ViewUtils
import DanXiKit

struct FloorEditSheet: View {
    @ObservedObject private var profileStore = ProfileStore.shared
    @EnvironmentObject private var model: HoleModel
    
    private let floorId: Int
    @State private var content: String
    @State private var runningImageUploadTask = 0
    @State private var specialTag = ""
    @State private var foldReason = ""
    
    init(floor: Floor) {
        self.floorId = floor.id
        self._content = State(initialValue: floor.content)
    }
    
    var body: some View {
        Sheet("Edit Reply") {
            try await model.modifyFloor(floorId: floorId, content: content, specialTag: specialTag, fold: foldReason)
        } content: {
            if profileStore.isAdmin {
                Section("Admin Actions") {
                    TextField("Special Tag", text: $specialTag)
                    TextField("Fold Reason", text: $foldReason)
                }
            }
            
            ForumEditor(content: $content, runningImageUploadTasks: $runningImageUploadTask, initiallyFocused: !profileStore.isAdmin)
        }
        .completed(!content.isEmpty && runningImageUploadTask <= 0)
        .warnDiscard(!content.isEmpty || runningImageUploadTask > 0)
        .scrollDismissesKeyboard(.immediately)
    }
}
