import SwiftUI
import FudanKit
import ViewUtils
#if os(watchOS)
import WatchKit
#else
import UIKit
#endif

public struct LoginSheet: View {
    private let style: SheetStyle
    @ObservedObject private var model = CampusModel.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var password = ""
    @State private var failedAttempts = 0
    @State private var challenge: AuthenticationAPI.CaptchaChallenge?
    @State private var verifyCode = ""
    @State private var loadingCaptcha = true
    @State private var captchaError: String?
    @State private var captchaRefreshID = UUID()

    private var captchaImageData: Data? {
        challenge?.imageData
    }

    public init(style: SheetStyle = .independent) {
        self.style = style
    }
    
    public var body: some View {
        Sheet {
            do {
                try await model.login(username: username, password: password, challenge: challenge, verifyCode: verifyCode)
            }
            catch {
                failedAttempts += 1
                resetCaptcha()
                throw error
            }
        } content: {
            #if os(watchOS)
            
            Picker(selection: $model.studentType) {
                Text("Undergraduate", bundle: .module).tag(StudentType.undergrad)
                Text("Graduate", bundle: .module).tag(StudentType.grad)
                Text("Staff", bundle: .module).tag(StudentType.staff)
            } label: {
                Text("Student Type", bundle: .module)
            }
            
            TextField(String(localized: "Fudan.ID", bundle: .module), text: $username)

            SecureField(String(localized: "Password", bundle: .module), text: $password)
            captchaEntry
            captchaFooter
            
            #else
            
            FormTitle(title: String(localized: "Fudan Campus Account", bundle: .module), description: String(localized: "Login with Fudan campus account to access various campus services", bundle: .module))
            
            Section {
                LabeledEntry(String(localized: "Student Type", bundle: .module)) {
                    Picker(String(""), selection: $model.studentType) {
                        Text("Undergraduate", bundle: .module).tag(StudentType.undergrad)
                        Text("Graduate", bundle: .module).tag(StudentType.grad)
                        Text("Staff", bundle: .module).tag(StudentType.staff)
                    }
                }
                LabeledEntry(String(localized: "Fudan.ID", bundle: .module)) {
                    TextField(String(localized: "Fudan.ID", bundle: .module), text: $username)
                }
                LabeledEntry(String(localized: "Password", bundle: .module)) {
                    SecureField(String(localized: "Password", bundle: .module), text: $password)
                }
                captchaEntry
            } footer: {
                captchaFooter
            }
            
            #endif

            if failedAttempts >= 3 && !username.isEmpty && !password.isEmpty {
                Section {
                    Button {
                        model.forceLogin(username: username, password: password)
                        dismiss()
                    } label: {
                        Text("Ignore check and login", bundle: .module)
                    }
                } footer: {
                    Text("If credential validation is unavailable, you can continue without checking. Some campus services may remain unavailable.", bundle: .module)
                }
            }
        }
        .completed(!username.isEmpty && !password.isEmpty && !loadingCaptcha && captchaError == nil && (challenge == nil || !verifyCode.isEmpty))
        .submitText(String(localized: "Login", bundle: .module))
        .sheetStyle(style)
        .onChange(of: username) { _ in
            resetCaptcha()
        }
        .task(id: captchaRefreshID) {
            await loadCaptcha()
        }
    }

    @ViewBuilder
    private var captchaEntry: some View {
        if loadingCaptcha {
            LabeledEntry(String(localized: "Verification code", bundle: .module)) {
                ProgressView()
            }
        } else if captchaImageData != nil || captchaError != nil {
            LabeledEntry(String(localized: "Verification code", bundle: .module)) {
                TextField(String(localized: "Verification code", bundle: .module), text: $verifyCode)
                    #if !os(watchOS)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    #endif
                Button(String(localized: "Reload verification code", bundle: .module)) {
                    resetCaptcha()
                }
                .buttonStyle(.borderless)
                .fixedSize()
            }
        }
    }

    @ViewBuilder
    private var captchaFooter: some View {
        if let captchaError {
            Text(captchaError).foregroundStyle(.secondary)
        } else if let captchaImageData, let image = UIImage(data: captchaImageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 44)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityLabel(String(localized: "Verification code", bundle: .module))
        }
    }

    private func resetCaptcha() {
        challenge = nil
        verifyCode = ""
        captchaError = nil
        loadingCaptcha = true
        captchaRefreshID = UUID()
    }

    @MainActor
    private func loadCaptcha() async {
        let requestedUsername = username
        do {
            try await Task.sleep(for: .milliseconds(400))
            let result = try await AuthenticationAPI.requestCredentialCheckCaptcha(username: requestedUsername)
            try Task.checkCancellation()
            guard username == requestedUsername else { return }
            challenge = result
            loadingCaptcha = false
        } catch {
            guard !Task.isCancelled, username == requestedUsername else { return }
            captchaError = error.localizedDescription
            loadingCaptcha = false
        }
    }
}

#Preview {
    List {
        
    }
    .sheet(isPresented: .constant(true)) {
        LoginSheet()
    }
}
