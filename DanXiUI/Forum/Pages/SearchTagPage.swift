import SwiftUI
import ViewUtils
import DanXiKit

struct SearchTagPage: View {
    let tagName: String
    
    var body: some View {
        ForumList {
            AsyncCollection { holes in
                try await ForumAPI.listHolesByTag(tagName: tagName, startTime: holes.last?.timeUpdated)
            } content: { hole in
                Section {
                    HoleView(hole: hole)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(tagName)
        .watermark()
    }
}
