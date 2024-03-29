import SwiftUI

struct Sheet<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var loading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let content: Content
    let action: () async throws -> Void
    var titleText: LocalizedStringKey = ""
    var submitText: LocalizedStringKey = "Submit"
    var completed: Bool = true
    
    init(_ titleText: LocalizedStringKey = "",
         action: @escaping () async throws -> Void,
         @ViewBuilder content: () -> Content) {
        self.titleText = titleText
        self.action = action
        self.content = content()
    }
    
    func title(_ titleText: LocalizedStringKey) -> Sheet {
        var sheet = self
        sheet.titleText = titleText
        return sheet
    }
    
    func submitText(_ submitText: LocalizedStringKey) -> Sheet {
        var sheet = self
        sheet.submitText = submitText
        return sheet
    }
    
    func completed(_ completed: Bool) -> Sheet {
        var sheet = self
        sheet.completed = completed
        return sheet
    }
    
    func submit() {
        Task {
            do {
                loading = true
                defer { loading = false }
                try await action()
                dismiss()
            } catch {
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                content
                    .disabled(loading) // disable edit during submit process
            }
            .scrollContentBackground(.visible)
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if loading {
                        ProgressView()
                    } else {
                        Button {
                            submit()
                        } label: {
                            Text(submitText)
                                .bold()
                        }
                        .disabled(!completed)
                    }
                }
            }
            .alert("Error", isPresented: $showAlert) {
                
            } message: {
                Text(alertMessage)
            }
        }
    }
}
