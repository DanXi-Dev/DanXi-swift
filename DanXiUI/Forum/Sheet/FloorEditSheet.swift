import SwiftUI
import ViewUtils
import DanXiKit

struct FloorEditSheet: View {
    @ObservedObject private var profileStore = ProfileStore.shared
    @EnvironmentObject private var model: HoleModel
    
    private let floorId: Int
    @State private var content: String
    @State private var specialTag: String?
    @State private var foldReason: String?
    
    init(floor: Floor) {
        self.floorId = floor.id
        self._content = State(initialValue: floor.content)
        self._specialTag = State(initialValue: floor.specialTag)
        self._foldReason = State(initialValue: floor.fold)
    }
    
    var body: some View {
        Sheet(String(localized: "Edit Reply", bundle: .module)) {
            if !profileStore.isAdmin {
                specialTag = nil
                foldReason = nil
            }
            try await model.modifyFloor(floorId: floorId, content: content, specialTag: specialTag, fold: foldReason)
        } content: {
            if profileStore.isAdmin {
                Section {
                    TextField(String(localized: "Special Tag", bundle: .module), text: $specialTag)
                    TextField(String(localized: "Fold Reason", bundle: .module), text: $foldReason)
                } header: {
                    Text("Admin Actions", bundle: .module)
                }
            }
            
            ForumEditor(content: $content, initiallyFocused: !profileStore.isAdmin)
        }
        .completed(!content.isEmpty)
        .warnDiscard(!content.isEmpty)
        .scrollDismissesKeyboard(.immediately)
    }
}
