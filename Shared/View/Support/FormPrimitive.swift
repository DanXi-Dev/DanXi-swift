import SwiftUI


/// A primitive form to simplify code structure.
///
/// This structure is used in sheet structure where user taps confirm button to activate a submit action.
/// Usage:
/// ```
/// FormPrimitive(title: "...",
///                 ...) {
///     Section {
///       ...
///     }
/// }, action: {
///     // submit action
/// }
/// ```
struct FormPrimitive<Content: View>: View {
    let title: LocalizedStringKey
    let submitText: LocalizedStringKey
    let allowSubmit: Bool
    let errorTitle: LocalizedStringKey
    let loadingPrompt: LocalizedStringKey
    let needConfirmation: Bool
    let content: Content
    let action: () async throws -> Void
    
    @State var errorInfo = ""
    @State var showError = false
    @State var showConfirmation = false
    
    @State var loading = false
    @Environment(\.dismiss) private var dismiss
    
    /// Create a primitive form.
    /// - Parameters:
    ///   - title: Form title.
    ///   - submitText: Submit buttom text.
    ///   - allowSubmit: Whether to allow user to submit. This value depends on if all necessary fields are filled.
    ///   - errorTitle: Alert title when submit failed.
    ///   - loadingPrompt: Loading overlay prompt.
    ///   - needConfirmation: Pop an alert for confirmation before submitting.
    ///   - content: Content of the form.
    ///   - action: Function to sumbit.
    init(title: LocalizedStringKey,
         submitText: LocalizedStringKey = "Submit",
         allowSubmit: Bool,
         errorTitle: LocalizedStringKey = "Error",
         loadingPrompt: LocalizedStringKey = "Submitting...",
         needConfirmation: Bool = false,
         @ViewBuilder content: () -> Content,
         action: @escaping () async throws -> Void) {
        self.title = title
        self.submitText = submitText
        self.allowSubmit = allowSubmit
        self.errorTitle = errorTitle
        self.loadingPrompt = loadingPrompt
        self.needConfirmation = needConfirmation
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
            } catch {
                errorInfo = error.localizedDescription
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
                    if loading {
                        ProgressView()
                    } else {
                        Button {
                            if needConfirmation {
                                showConfirmation = true
                            } else {
                                submit()
                            }
                        } label: {
                            Text(submitText)
                                .bold()
                        }
                        .disabled(!allowSubmit)
                    }
                }
            }
            .alert(errorTitle, isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorInfo)
            }
            .alert("Confirm Submit", isPresented: $showConfirmation) {
                Button("Confirm", role: .destructive) {
                    submit()
                }
                Button("Cancel", role: .cancel) { }
            }
            .loadingOverlay(loading: loading, prompt: loadingPrompt)
        }
    }
}
