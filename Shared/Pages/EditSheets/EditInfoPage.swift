import SwiftUI

struct EditInfoPage: View {
    
    let holeId: Int
    @State var divisionId: Int
    @State var tags: [THTag]
    
    
    @Environment(\.dismiss) private var dismiss
    
    @State var loading = false
    @State var showError = false
    @State var errorInfo = ErrorInfo()
    
    func editInfo() {
        Task {
            Task {
                loading = true
                defer { loading = false }
                
                do {
                    try await NetworkRequests.shared.alterHole(holeId: holeId,
                                                               tags: tags,
                                                               divisionId: divisionId)
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
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker(selection: $divisionId, label: Label("Select Division", systemImage: "rectangle.3.group")) {
                        ForEach(TreeholeDataModel.shared.divisions) { division in
                            Text(division.name)
                                .tag(division.id)
                        }
                    }
                }
                
                TagField(tags: $tags, max: 5)
            }
            .navigationTitle("Edit Post Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: editInfo) {
                        Text("Submit")
                            .bold()
                    }
                    .disabled(tags.isEmpty)
                }
            }
            .alert("Edit Post Info Failed", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorInfo.description)
            }
            .overlay(
                HStack(alignment: .center, spacing: 20) {
                    ProgressView()
                    Text("Submitting...")
                        .foregroundColor(.secondary)
                        .bold()
                }
                    .padding(35)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .animation(.easeInOut, value: loading)
                    .opacity(loading ? 1 : 0)
            )
        }
    }
}

struct EditInfoPage_Previews: PreviewProvider {
    static var previews: some View {
        EditInfoPage(holeId: 0, divisionId: 0, tags: [])
    }
}
