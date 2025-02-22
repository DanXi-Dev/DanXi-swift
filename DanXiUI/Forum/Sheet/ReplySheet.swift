import SwiftUI
import ViewUtils
import DanXiKit

struct ReplySheet: View {
    @ObservedObject private var profileStore = ProfileStore.shared
    @EnvironmentObject private var model: HoleModel
    @State private var content: String
    @State private var specialTag: String = ""
    
    @State private var hasSubmitted = false
    private let replyTo: Int?
    
    init(content: String = "", replyTo: Int? = nil) {
        self._content = State(initialValue: content)
        self.replyTo = replyTo
    }
    
    var body: some View {
        Sheet(String(localized: "Reply", bundle: .module)) {
            try await model.reply(content: content, specialTag: specialTag)
            hasSubmitted = true
            await DraftboxStore.shared.deleteReplyDraft(holeId: model.hole.id, replyTo: replyTo)
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
        .onDisappear {
            Task {
                if !hasSubmitted {
                    DraftboxStore.shared.addReplyDraft(content: content, holeId: model.hole.id, replyTo: replyTo)
                }
            }
        }
    }
}

#Preview {
    let hole: Hole = decodePreviewData(filename: "hole", directory: "forum")
    let floors: [Floor] = decodePreviewData(filename: "floors", directory: "forum")
    let holeModel = HoleModel(hole: hole, floors: floors)
    
    ReplySheet()
        .environmentObject(holeModel)
}
