import SwiftUI

struct ReplyPage: View {
    let holeId: Int
    @State var content: String
    @Binding var endReached: Bool
    let floors: [THFloor]
    
    init(holeId: Int,
         content: String = "",
         floors: [THFloor] = [],
         endReached: Binding<Bool>) {
        self.holeId = holeId
        self._content = State(initialValue: content)
        self.floors = floors
        self._endReached = endReached
    }
    
    var body: some View {
        PrimitiveForm(title: "Reply",
                      allowSubmit: !content.isEmpty,
                      errorTitle: "Send Reply Failed") {
            Section {
                TextEditView($content,
                             placeholder: "Enter reply content")
            } header: {
                Text("TH Edit Alert")
            }
            .textCase(nil)
            
            if !content.isEmpty {
                Section {
                    ReferenceView(content, floors: floors)
                        .padding(.vertical, 5)
                } header: {
                    Text("Preview")
                }
            }
        } action: {
            _ = try await NetworkRequests.shared.reply(content: content, holdId: holeId)
            Task { @MainActor in
                endReached = false
            }
        }
    }
}

struct ReplyPage_Previews: PreviewProvider {
    static var previews: some View {
        ReplyPage(holeId: 0,
                  content: "Hello this is some content",
                  endReached: .constant(false))
    }
}
