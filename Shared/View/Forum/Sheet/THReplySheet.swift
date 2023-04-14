import SwiftUI

struct THReplySheet: View {
    @EnvironmentObject var model: THHoleModel
    @State var content: String
    
    init(_ content: String = "") {
        self._content = State(initialValue: content)
    }
    
    var body: some View {
        Sheet("Reply") {
            try await model.reply(content)
        } content: {
            THContentEditor(content: $content)
        }
        .completed(!content.isEmpty)
        .scrollDismissesKeyboard(.immediately)
    }
}
