import SwiftUI

struct ReplyPage: View {
    let holeId: Int
    @Binding var showReplyPage: Bool
    @State var content = ""
    
    func reply() async {
        do {
            _ = try await networks.reply(content: content, holdId: holeId)
            showReplyPage = false
        } catch {
            print("DANXI-DEBUG: reply failed")
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    editor
                } header: {
                    Text("th_edit_alert")
                }
                .textCase(nil)
            }
            .navigationTitle("reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button("send") {
                        Task {
                            await reply()
                        }
                    }
                }
            }
        }
    }
    
    private var editor: some View {
        ZStack(alignment: .topLeading) {
            if content.isEmpty {
                Text("th_edit_prompt")
                    .foregroundColor(.primary.opacity(0.25))
                    .padding(.top, 7)
                    .padding(.leading, 4)
            }
            TextEditor(text: $content)
                .frame(height: 250)
        }
    }
}

struct ReplyPage_Previews: PreviewProvider {
    static var previews: some View {
        ReplyPage(holeId: 0, showReplyPage: .constant(true))
    }
}
