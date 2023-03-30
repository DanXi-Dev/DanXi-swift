import SwiftUI

struct THMyPostPage: View {
    @State var holes: [THHole] = []
    
    func loadMore() async {
        do {
            let newHoles = try await THRequests.loadMyHoles(startTime: holes.last?.updateTime)
            holes.append(contentsOf: newHoles)
        } catch {
            print(error)
        }
    }
    
    var body: some View {
        List {
            ForEach(holes) { hole in
                THHoleView(hole: hole)
                    .task {
                        if hole == holes.last {
                            await loadMore()
                        }
                    }
            }
        }
        .task {
            await loadMore()
        }
        .animation(.default, value: holes)
        .listStyle(.inset)
        .navigationTitle("My Post")
    }
}
