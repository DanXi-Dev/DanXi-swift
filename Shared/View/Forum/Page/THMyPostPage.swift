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
        .sectionSpacing(10)
        .navigationTitle("My Post")
    }
}
