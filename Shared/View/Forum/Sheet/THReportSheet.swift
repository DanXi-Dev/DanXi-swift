import SwiftUI

struct THReportSheet: View {
    @EnvironmentObject var model: THFloorModel
    @State var reason = ""
    
    var body: some View {
        Sheet("Report") {
            try await THRequests.report(floorId: model.floor.id, reason: reason)
        } content: {
            Section {
                ScrollView(.vertical, showsIndicators: false) {
                    THFloorContent(model.floor.content)
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
    }
}
