import SwiftUI
import SwiftUIX
import DanXiKit

struct ForumContentPreview: View {
    private let sections: [FloorSection]
    
    init(sections: [FloorSection]) {
        self.sections = sections
    }
    
    init(content: String, contextMentions: [Mention] = [], contextFloors: [Floor] = []) {
        self.sections = parseFloorContent(content: content, mentions: contextMentions, floors: contextFloors)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                switch section {
                case .text(let markdown):
                    CustomMarkdown(markdown)
                case .localMention(let floor):
                    MentionView(floor)
                case .remoteMention(let mention):
                    MentionView(mention)
                }
            }
        }
    }
}
