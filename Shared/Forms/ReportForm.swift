import SwiftUI

struct ReportForm: View {
    let floor: THFloor
    @State var reportReason = ""
    
    var body: some View {
        PrimitiveForm(title: "Report",
                      allowSubmit: !reportReason.isEmpty,
                      errorTitle: "Report Failed") {
            Section {
                ScrollView(.vertical, showsIndicators: false) {
                    ReferenceView(floor.content,
                                  mentions: floor.mention)
                }
                .frame(maxHeight: 200)
            } header: {
                Label("Content to Report", systemImage: "text.alignleft")
            }
            
            Section {
                TextField("Enter report reason", text: $reportReason)
            }
        } action: {
            try await NetworkRequests.shared.report(floorId: floor.id,
                                                    reason: reportReason)
        }
    }
}

struct ReportForm_Previews: PreviewProvider {
    static var previews: some View {
        ReportForm(floor: PreviewDecode.decodeObj(name: "long-floor")!)
    }
}
