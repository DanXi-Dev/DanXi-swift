import SwiftUI

struct ReplyPage: View {
    let holeId: Int
    @State var content: String
    @State var loading = false
    @Environment(\.dismiss) private var dismiss
    
    func reply() async {
        loading = true
        defer { loading = false }
        do {
            _ = try await NetworkRequests.shared.reply(content: content, holdId: holeId)
            dismiss()
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

struct ReplyPage_Previews: PreviewProvider {
    static var previews: some View {
        ReplyPage(holeId: 0, content: "")
    }
}
