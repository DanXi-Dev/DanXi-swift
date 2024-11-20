import SwiftUI
import ViewUtils
import DanXiKit

struct ReplySheet: View {
    @EnvironmentObject private var model: HoleModel
    @State private var content: String
    
    init(content: String = "") {
        self._content = State(initialValue: content)
    }
    
    var body: some View {
        Sheet(String(localized: "Reply", bundle: .module)) {
            try await model.reply(content: content)
        } content: {
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
