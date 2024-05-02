import SwiftUI
import ViewUtils
import DanXiKit

struct MyPostPage: View {
    var body: some View {
        ForumList {
            AsyncCollection { holes in
                try await ForumAPI.listMyHoles(startTime: holes.last?.timeUpdated)
            } content: { hole in
                Section {
                    HoleView(hole: hole)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }
            }
        }
        .navigationTitle("My Post")
        .navigationBarTitleDisplayMode(.inline)
        .watermark()
    }
}
