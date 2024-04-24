import SwiftUI
import ViewUtils
import DanXiKit

struct ReportSheet: View {
    let presentation: FloorPresentation
    @State private var reason = ""
    
    var body: some View {
        Sheet("Report") {
            try await ForumAPI.createReport(floorId: presentation.floor.id, reason: reason)
        } content: {
            Section {
                ScrollView(.vertical, showsIndicators: false) {
                    ForumContentPreview(sections: presentation.sections)
                }
                .frame(maxHeight: 200)
            } header: {
                Label("Content to Report", systemImage: "text.alignleft")
            }
            
            Section {
                TextField("Enter report reason", text: $reason)
            }
        }
        .completed(!reason.isEmpty)
        .warnDiscard(!reason.isEmpty)
    }
}
