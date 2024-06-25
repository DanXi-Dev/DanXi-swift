import SwiftUI
import ViewUtils
import DanXiKit

struct ReportSheet: View {
    let presentation: FloorPresentation
    @State private var reason = ""
    
    var body: some View {
        Sheet(String(localized: "Report", bundle: .module)) {
            try await ForumAPI.createReport(floorId: presentation.floor.id, reason: reason)
        } content: {
            Section {
                ScrollView(.vertical, showsIndicators: false) {
                    ForumContentPreview(sections: presentation.sections)
                }
                .frame(maxHeight: 200)
            } header: {
                Label(String(localized: "Content to Report", bundle: .module), systemImage: "text.alignleft")
            }
            
            Section {
                TextField(String(localized: "Enter report reason", bundle: .module), text: $reason)
            }
        }
        .completed(!reason.isEmpty)
        .warnDiscard(!reason.isEmpty)
    }
}
