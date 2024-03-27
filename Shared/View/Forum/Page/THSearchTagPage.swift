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
                }
            }
        }
        .sectionSpacing(10)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(tagname)
    }
}
