import SwiftUI

struct THMyPostPage: View {
    var body: some View {
        List {
            AsyncCollection { holes in
                try await THRequests.loadMyHoles(startTime: holes.last?.updateTime)
            } content: { hole in
                THHoleView(hole: hole)
            }
        }
        .listStyle(.inset)
        .navigationTitle("My Post")
    }
}
