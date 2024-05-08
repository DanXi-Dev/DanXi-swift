import SwiftUI
import ViewUtils
import DanXiKit

struct SearchTagPage: View {
    let tagName: String
    
    var body: some View {
        ForumList {
            AsyncCollection { (presentations: [HolePresentation]) in
                let holes = try await ForumAPI.listHolesByTag(tagName: tagName, startTime: presentations.last?.hole.timeUpdated)
                return holes.map { HolePresentation(hole: $0) }
            } content: { presentation in
                Section {
                    HoleView(presentation: presentation)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(tagName)
        .watermark()
    }
}
