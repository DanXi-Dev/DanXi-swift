import SwiftUI
import ViewUtils
import DanXiKit

struct ReplySheet: View {
    @ObservedObject private var profileStore = ProfileStore.shared
    @EnvironmentObject private var model: HoleModel
    @State private var content: String
    @State private var specialTag: String = ""
    
    init(content: String = "") {
        self._content = State(initialValue: content)
    }
    
    var body: some View {
        Sheet(String(localized: "Reply", bundle: .module)) {
            try await model.reply(content: content, specialTag: specialTag)
        } content: {
            if profileStore.isAdmin {
                Section {
                    TextField(String(localized: "Special Tag", bundle: .module), text: $specialTag)
                } header: {
                    Text("Admin Actions", bundle: .module)
                }
            }
            ForumEditor(content: $content, initiallyFocused: true)
        }
        .completed(!content.isEmpty)
        .warnDiscard(!content.isEmpty)
    }
}

#Preview {
    let hole: Hole = decodePreviewData(filename: "hole", directory: "forum")
    let floors: [Floor] = decodePreviewData(filename: "floors", directory: "forum")
    let holeModel = HoleModel(hole: hole, floors: floors)
    
    ReplySheet()
        .environmentObject(holeModel)
}
