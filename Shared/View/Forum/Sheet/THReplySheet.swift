import SwiftUI

struct THReplySheet: View {
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
        FormPrimitive(title: "Reply",
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
                    THContentView(content, floors: floors)
                        .interactable(false)
                        .padding(.vertical, 5)
                } header: {
                    Text("Preview")
                }
            }
        } action: {
            _ = try await THRequests.createFloor(content: content, holeId: holeId)
            Task { @MainActor in
                endReached = false
            }
        }
    }
}

struct THReplySheet_Previews: PreviewProvider {
    static var previews: some View {
        THReplySheet(holeId: 0,
                  content: "Hello this is some content",
                  endReached: .constant(false))
    }
}
