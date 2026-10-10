import SwiftUI
import FudanKit
import DanXiKit
import DanXiUI
import ViewUtils

struct DebugPage: View {
    @State private var showQuestionSheet = false
    @State private var resetURLSuccessAlert = false
    @ObservedObject private var settings = ForumSettings.shared
    @AppStorage("watermark-unlocked") private var watermarkUnlocked = true
    
    private func resetBaseURLs() {
        guard let urls = UIPasteboard.general.string else { return }
        let lines = urls.split(separator: "\n")
        guard lines.count == 3 else { return }
        let authURL = URL(string: String(lines[0]))
        let forumURL = URL(string: String(lines[1]))
        let curriculumURL = URL(string: String(lines[2]))
        
        guard let authURL, let forumURL, let curriculumURL else { return }
        
        UserDefaults.standard.set(authURL.absoluteString, forKey: "fduhole_auth_url")
        UserDefaults.standard.set(forumURL.absoluteString, forKey: "fduhole_base_url")
        UserDefaults.standard.set(curriculumURL.absoluteString, forKey: "danke_base_url")
        
        DanXiKit.authURL = authURL
        DanXiKit.forumURL = forumURL
        DanXiKit.curriculumURL = curriculumURL
        
        resetURLSuccessAlert = true
    }
    
    var body: some View {
        List {
            Section {
                Button {
                    showQuestionSheet = true
                } label: {
                    Text("Register Questions")
                }
            }
            
            Section {
                Button {
                    resetBaseURLs()
                } label: {
                    Text("Reset Base URLs")
                }
                
            } footer: {
                Text("Paste the backend URLs in three lines, separated by newlines, in the order of `auth`, `forum` and `curriculum`.")
            }
            
            if watermarkUnlocked {
                Section {
                    Toggle(isOn: $settings.screenshotAlert) {
                        Label("Screenshot Alert", systemImage: "camera.viewfinder")
                    }
                    
                    Stepper("Watermark Opacity \(String(format: "%.3f", settings.watermarkOpacity))", value: settings.$watermarkOpacity, step: 0.002)

                    NavigationLink {
                        SecondaryCredentialPage()
                    } label: {
                        Text(verbatim: "Secondary Credential")
                    }
                }
            }
        }
        .navigationTitle("Debug")
        .sheet(isPresented: $showQuestionSheet) {
            QuestionSheet()
        }
        .alert("Reset URLs Success", isPresented: $resetURLSuccessAlert) {
            
        }
    }
}

private struct SecondaryCredentialPage: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username: String
    @State private var password: String

    init() {
        let credential = CredentialStore.shared.secondaryCredential
        _username = State(initialValue: credential?.username ?? "")
        _password = State(initialValue: credential?.password ?? "")
    }

    private func setCredential(_ credential: Credential?) {
        CredentialStore.shared.setSecondaryCredential(credential)
        Task {
            await WalletStore.shared.clearCache()
            dismiss()
        }
    }

    var body: some View {
        Form {
            TextField(text: $username, prompt: Text(verbatim: "Username")) {
                Text(verbatim: "Username")
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            SecureField(text: $password, prompt: Text(verbatim: "Password")) {
                Text(verbatim: "Password")
            }

            if CredentialStore.shared.secondaryCredential != nil {
                Button(role: .destructive) {
                    setCredential(nil)
                } label: {
                    Text(verbatim: "Clear Secondary Credential")
                }
            }
        }
        .navigationTitle(Text(verbatim: "Secondary Credential"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    setCredential(Credential(username: username, password: password))
                } label: {
                    Text(verbatim: "Save")
                }
                .disabled(username.isEmpty || password.isEmpty)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DebugPage()
    }
}
