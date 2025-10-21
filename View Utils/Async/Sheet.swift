import SwiftUI
import FudanKit

public enum SheetStyle {
    case independent, subpage
}

public struct Sheet<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) var openURL
    
    @State private var loading = false
    @State private var showAlert = false
    @State private var showCaptchaAlert = false
    @State private var alertMessage = ""
    @State private var showDiscardWarning = false
    
    let content: Content
    let action: () async throws -> Void
    var titleText: String = ""
    var submitText: String = String(localized: "Submit", bundle: .module)
    var completed: Bool = true
    var style: SheetStyle = .independent
    var discardWarningNeeded: Bool = false
    
    public init(_ titleText: String = "",
         action: @escaping () async throws -> Void,
         @ViewBuilder content: () -> Content) {
        self.titleText = titleText
        self.action = action
        self.content = content()
    }
    
    public func title(_ titleText: String) -> Sheet {
        var sheet = self
        sheet.titleText = titleText
        return sheet
    }
    
    public func submitText(_ submitText: String) -> Sheet {
        var sheet = self
        sheet.submitText = submitText
        return sheet
    }
    
    public func completed(_ completed: Bool) -> Sheet {
        var sheet = self
        sheet.completed = completed
        return sheet
    }
    
    public func sheetStyle(_ style: SheetStyle = .independent) -> Sheet {
        var sheet = self
        sheet.style = style
        return sheet
    }
    
    public func warnDiscard(_ warn: Bool) -> Sheet {
        var sheet = self
        sheet.discardWarningNeeded = warn
        return sheet
    }
    
    private func submit() {
        Task {
            do {
                loading = true
                defer { loading = false }
                try await action()
                await MainActor.run {
                    dismiss() // SwiftUI view updates must be published on the main thread
                }
            } catch {
                alertMessage = error.localizedDescription
                switch error {
                    case CampusError.needCaptcha:
                        showCaptchaAlert = true
                    default:
                        showAlert = true
                }
            }
        }
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                content
                    .disabled(loading) // disable edit during submit process
            }
            .scrollContentBackground(.visible)
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if style == .independent {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            if discardWarningNeeded {
                                showDiscardWarning = true
                            } else {
                                dismiss()
                            }
                        } label: {
                            Text("Cancel", bundle: .module)
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
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
        }
        //regular alert
        .alert(String(localized: "Error", bundle: .module), isPresented: $showAlert) {
            
        } message: {
            Text(alertMessage)
        }
        //captcha alert
        .alert(String(localized: "Error", bundle: .module), isPresented: $showCaptchaAlert) {
            Button {
                
            } label: {
                Text("Cancel", bundle: .module)
            }
            
            Button {
                openURL(URL(string: "https://uis.fudan.edu.cn")!)
            } label: {
                Text("Go to Browser", bundle: .module)
            }
        } message: {
            Text("Need captcha, visit UIS webpage to login.", bundle: .module)
        }
        //unsaved alert
        .alert(String(localized: "Unsaved Changes", bundle: .module), isPresented: $showDiscardWarning) {
            Button(String(localized: "Cancel", bundle: .module), role: .cancel) {
                showDiscardWarning = false
            }
            Button(String(localized: "Discard", bundle: .module), role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Are your sure you want to discard your contents? Your messages will be lost.", bundle: .module)
        }
        #if !os(watchOS)
        .interactiveDismiss(canDismissSheet: !discardWarningNeeded) {
            showDiscardWarning = true
        }
        #endif
    }
}
