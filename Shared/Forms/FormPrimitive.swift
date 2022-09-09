import SwiftUI

struct FormPrimitive<Content: View>: View {
    let title: LocalizedStringKey
    let submitText: LocalizedStringKey
    let allowSubmit: Bool
    let errorTitle: LocalizedStringKey
    let loadingPrompt: LocalizedStringKey
    let content: Content
    let action: () async throws -> Void
    
    @State var errorInfo = ErrorInfo()
    @State var showError = false
    
    @State var loading = false
    @Environment(\.dismiss) private var dismiss
    
    init(title: LocalizedStringKey,
         submitText: LocalizedStringKey = "Submit",
         allowSubmit: Bool,
         errorTitle: LocalizedStringKey = "Error",
         loadingPrompt: LocalizedStringKey = "Submitting...",
         @ViewBuilder content: () -> Content,
         action: @escaping () async throws -> Void) {
        self.title = title
        self.submitText = submitText
        self.allowSubmit = allowSubmit
        self.errorTitle = errorTitle
        self.loadingPrompt = loadingPrompt
        self.content = content()
        self.action = action
    }
    
    func submit() {
        Task {
            do {
                loading = true
                defer { loading = false }
                
                try await action()
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
    
    var body: some View {
        NavigationView {
            Form {
                content
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        submit()
                    } label: {
                        Text(submitText)
                            .bold()
                    }
                    .disabled(!allowSubmit || loading)
                }
            }
            .alert(errorTitle, isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorInfo.description)
            }
            .loadingOverlay(loading: loading, prompt: loadingPrompt)
        }
    }
}
