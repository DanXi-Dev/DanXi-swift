import SwiftUI

struct ReplyPage: View {
    let holeId: Int
    @State var content: String
    @Binding var endReached: Bool
    let floors: [THFloor]
    
    @State var loading = false
    @Environment(\.dismiss) private var dismiss
    
    @State var showError = false
    @State var errorInfo = ErrorInfo()
    
    init(holeId: Int,
         content: String = "",
         floors: [THFloor] = [],
         endReached: Binding<Bool>) {
        self.holeId = holeId
        self._content = State(initialValue: content)
        self.floors = floors
        self._endReached = endReached
    }
    
    func reply() async {
        loading = true
        defer { loading = false }
        do {
            _ = try await NetworkRequests.shared.reply(content: content, holdId: holeId)
            Task { @MainActor in
                endReached = false
            }
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
                
                if !content.isEmpty {
                    Section {
                        ReferenceView(content, floors: floors)
                            .padding(.vertical, 5)
                    } header: {
                        Text("Preview")
                    }
                }
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
                    .disabled(loading || content.isEmpty)
                }
            }
            .alert("Send Reply Failed", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorInfo.description)
            }
            .overlay(
                HStack(alignment: .center, spacing: 20) {
                    ProgressView()
                    Text("Sending Reply...")
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
}

struct ReplyPage_Previews: PreviewProvider {
    static var previews: some View {
        ReplyPage(holeId: 0,
                  content: "Hello this is some content",
                  endReached: .constant(false))
    }
}
