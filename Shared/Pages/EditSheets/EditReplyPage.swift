import SwiftUI

struct EditReplyPage: View {
    @Binding var floor: THFloor
    @State var content: String
    
    @State var loading = false
    @Environment(\.dismiss) private var dismiss
    
    @State var showError = false
    @State var errorInfo = ErrorInfo()
    
    func edit() async {
        do {
            loading = true
            defer { loading = false }
            floor = try await NetworkRequests.shared.editReply(content: content, floorId: floor.id)
            dismiss()
        } catch let error as NetworkError {
            errorInfo = error.localizedErrorDescription
            showError = true
        } catch {
            errorInfo = ErrorInfo(title: "Unknown Error",
                                  description: "Error description: \(error.localizedDescription)")
            showError = true
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextEditView($content,
                                 placeholder: "Enter reply content")
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
                    .disabled(loading || content.isEmpty)
                }
            }
            .alert("Edit Reply Failed", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorInfo.description)
            }
            .overlay(
                HStack(alignment: .center, spacing: 20) {
                    ProgressView()
                    Text("Editing Reply...")
                        .foregroundColor(.secondary)
                        .bold()
                }
                    .padding(35)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .animation(.easeInOut, value: loading)
                    .opacity(loading ? 1 : 0)
            )
            .ignoresSafeArea(.keyboard) // prevent keyboard from pushing up loading overlay
        }
    }
    
    @MainActor
    private func renderedContent(_ content: String) -> some View {
        let contentElements = parseMarkdownReferences(content)
        
        return VStack(alignment: .leading, spacing: 7) {
            ForEach(contentElements) { element in
                switch element {
                case .text(let content):
                    MarkdownView(content)
                        .textSelection(.enabled)
                    
                case .localReference(let floor):
                    MentionView(floor: floor)
                    
                case .remoteReference(let mention):
                    MentionView(mention: mention)
                    
                case .reference(let floorId):
                    Text("NOT SUPPOTED MENTION: \(String(floorId))")
                        .foregroundColor(.red)
                }
            }
        }
    }
}

struct EditReplyPage_Previews: PreviewProvider {
    static var previews: some View {
        EditReplyPage(floor: .constant(PreviewDecode.decodeObj(name: "floor")!),
                      content: "")
    }
}
