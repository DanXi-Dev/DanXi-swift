import SwiftUI

struct ReplyPage: View {
    let holeId: Int
    @Binding var showReplyPage: Bool
    @State var content: String
    
    func reply() async {
        do {
            _ = try await NetworkRequests.shared.reply(content: content, holdId: holeId)
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
                    Text("TH Edit Alert")
                }
                .textCase(nil)
            }
            .navigationTitle("Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button {
                        Task {
                            await reply()
                        }
                    } label: {
                        Text("Send")
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

struct ReplyPage_Previews: PreviewProvider {
    static var previews: some View {
        ReplyPage(holeId: 0, showReplyPage: .constant(true), content: "")
    }
}
