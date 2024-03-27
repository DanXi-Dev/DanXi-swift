import SwiftUI
import ViewUtils

struct THMyPostPage: View {
    var body: some View {
        THBackgroundList {
            AsyncCollection { holes in
                try await THRequests.loadMyHoles(startTime: holes.last?.updateTime)
            } content: { hole in
                Section {
                    THHoleView(hole: hole)
                }
            }
        }
        .sectionSpacing(8)
        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
        .navigationTitle("My Post")
        .navigationBarTitleDisplayMode(.inline)
    }
}
