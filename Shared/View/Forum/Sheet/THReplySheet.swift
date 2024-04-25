import SwiftUI

struct THReplySheet: View {
    @EnvironmentObject private var model: THHoleModel
    @State private var content: String
    @State private var runningImageUploadTask = 0
    
    init(_ content: String = "") {
        self._content = State(initialValue: content)
    }
    
    var body: some View {
        Sheet("Reply") {
            try await model.reply(content)
        } content: {
            THContentEditor(content: $content, runningImageUploadTasks: $runningImageUploadTask, initiallyFocused: true)
        }
        .completed(!content.isEmpty && runningImageUploadTask <= 0)
        .warnDiscard(!content.isEmpty || runningImageUploadTask > 0)
    }
}
