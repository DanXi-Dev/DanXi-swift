import SwiftUI

struct ReportForm: View {
    let floor: THFloor
    @State var reportReason = ""
    
    var body: some View {
        FormPrimitive(title: "Report",
                      allowSubmit: !reportReason.isEmpty,
                      errorTitle: "Report Failed",
                      needConfirmation: true) {
            Section {
                ScrollView(.vertical, showsIndicators: false) {
                    ReferenceView(floor.content,
                                  mentions: floor.mention,
                                  interactable: false)
                }
                .frame(maxHeight: 200)
            } header: {
                Label("Content to Report", systemImage: "text.alignleft")
            }
            
            Section {
                TextField("Enter report reason", text: $reportReason)
            }
        } action: {
            try await TreeholeRequests.report(floorId: floor.id,
                                                    reason: reportReason)
        }
    }
}

struct ReportForm_Previews: PreviewProvider {
    static var previews: some View {
        ReportForm(floor: Bundle.main.decodeData("long-floor"))
    }
}
