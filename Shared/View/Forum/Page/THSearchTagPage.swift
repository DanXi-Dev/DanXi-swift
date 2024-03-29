import SwiftUI
import ViewUtils

struct THSearchTagPage: View {
    let tagname: String
    
    var body: some View {
        THBackgroundList {
            AsyncCollection { holes in
                try await THRequests.listHoleByTag(tagName: tagname, startTime: holes.last?.updateTime.ISO8601Format())
            } content: { hole in
                Section {
                    THHoleView(hole: hole)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(tagname)
    }
}
