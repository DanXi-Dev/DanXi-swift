import SwiftUI

/// View that parse and render Markdown and mention syntax
struct ReferenceView: View {
    let content: String
    let elements: [MarkdownElements]
    let proxy: ScrollViewProxy?
    
    init(_ content: String,
         proxy: ScrollViewProxy? = nil,
         mentions: [THMention] = [],
         floors: [THFloor] = []) {
        self.content = content
        self.proxy = proxy
        elements = parseReferences(content,
                                   mentions: mentions,
                                   floors: floors)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(elements) { element in
                switch element {
                case .text(let content):
                    MarkdownView(content)
                        .textSelection(.enabled)
                    
                case .localReference(let floor):
                    MentionView(floor: floor, proxy: proxy)
                    
                case .remoteReference(let mention):
                    MentionView(mention: mention)
                        .foregroundColor(.red)
                    
                case .reference(let floorId):
                    RemoteMentionView(floorId: floorId)
                }
            }
        }
    }
}
