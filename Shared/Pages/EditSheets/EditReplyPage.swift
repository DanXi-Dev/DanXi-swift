import SwiftUI

struct EditReplyPage: View {
    @Binding var floor: THFloor
    @State var content: String
    @State var loading = false
    
    @Environment(\.dismiss) private var dismiss
    
    func edit() async {
        do {
            loading = true
            defer { loading = false }
            floor = try await NetworkRequests.shared.editReply(content: content, floorId: floor.id)
            dismiss()
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
            .navigationTitle("Edit Reply")
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
                    .disabled(loading)
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
        EditReplyPage(floor: .constant(PreviewDecode.decodeObj(name: "floor")!), content: "")
    }
}
