import SwiftUI

struct EditReplyPage: View {
    @Binding var floor: THFloor
    @State var content: String
    @Binding var showPage: Bool
    
    func edit() async {
        do {
            floor = try await NetworkRequests.shared.editReply(content: content, floorId: floor.id)
            showPage = false
        } catch {
            print("DANXI-DEBUG: edit reply failed")
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    editor
                } header: {
                    Text("TH Edit Alert")
                }
                .textCase(nil)
            }
            .navigationTitle("Edit reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button {
                        Task {
                            await edit()
                        }
                    } label: {
                        Text("Edit")
                            .bold()
                    }
                }
            }
        }
    }
    
    private var editor: some View {
        ZStack(alignment: .topLeading) {
            if content.isEmpty {
                Text("Enter post content")
                    .foregroundColor(.primary.opacity(0.25))
                    .padding(.top, 7)
                    .padding(.leading, 4)
            }
            TextEditor(text: $content)
                .frame(height: 250)
        }
    }
}

struct EditReplyPage_Previews: PreviewProvider {
    static var previews: some View {
        EditReplyPage(floor: .constant(PreviewDecode.decodeObj(name: "floor")!), content: "", showPage: .constant(true))
    }
}
