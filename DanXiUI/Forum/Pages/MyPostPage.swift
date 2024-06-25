import SwiftUI
import ViewUtils
import DanXiKit

struct MyPostPage: View {
    var body: some View {
        ForumList {
            AsyncCollection { (presentations: [HolePresentation]) in
                let holes = try await ForumAPI.listMyHoles(startTime: presentations.last?.hole.timeUpdated)
                return holes.map { HolePresentation(hole: $0) }
            } content: { presentation in
                Section {
                    HoleView(presentation: presentation)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }
            }
        }
        .navigationTitle(String(localized: "My Post", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .watermark()
    }
}
