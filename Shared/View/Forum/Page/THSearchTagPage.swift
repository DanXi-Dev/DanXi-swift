import SwiftUI

struct THSearchTagPage: View {
    let tagname: String
    
    var body: some View {
        THBackgroundList {
            AsyncCollection { holes in
                try await THRequests.listHoleByTag(tagName: tagname, startTime: holes.last?.updateTime.ISO8601Format())
            } content: { hole in
                THHoleView(hole: hole)
            }
        }
        .listStyle(.inset)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(tagname)
    }
}
