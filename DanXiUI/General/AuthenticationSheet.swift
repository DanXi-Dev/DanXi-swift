import CryptoKit
import DanXiKit
import SwiftUI
import Utils
import ViewUtils

public struct AuthenticationSheet: View {
    @StateObject private var model = AuthenticationModel()
    @Environment(\.dismiss) private var dismiss
    let style: SheetStyle
    
    public init(style: SheetStyle = .independent) {
        self.style = style
    }
    
    public var body: some View {
//        NavigationStack {
            LoginSheet(style: style)
//        }
        .onChange(of: model.done) { done in
            if done {
                dismiss()
            }
        }
        .environmentObject(model)
    }
}

class AuthenticationModel: ObservableObject {
    @Published var done = false
}

// MARK: - Login

private struct LoginSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authModel: AuthenticationModel
    @StateObject private var model = LoginModel()
    @FocusState private var usernameFocus: Bool
    let style: SheetStyle
    
    init(style: SheetStyle = .independent) {
        self.style = style
    }
    
    var body: some View {
        Sheet {
            try await model.login()
            authModel.done = true
        } content: {
            FormTitle(title: String(localized: "DanXi Account", bundle: .module),
                      description: String(localized: "DanXi account is used to access community services such as Treehole and DanKe.", bundle: .module))
            
            Section {
                LabeledEntry(String(localized: "Email", bundle: .module)) {
                    TextField(String(localized: "Required", bundle: .module), text: $model.username)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .focused($usernameFocus)
                }
                
                LabeledEntry(String(localized: "Password", bundle: .module)) {
                    SecureField(String(localized: "Required", bundle: .module), text: $model.password)
                }
            } footer: {
                HStack(spacing: 20) {
                    Spacer()
                    NavigationLink(String(localized: "Register", bundle: .module)) {
                        RegisterSheet(type: .register)
                    }
                    NavigationLink(String(localized: "Forget Password", bundle: .module)) {
                        RegisterSheet(type: .forgetPassword)
                    }
                }
                .padding(.top)
            }
        }
        .completed(model.completed)
        .submitText(String(localized: "Login", bundle: .module))
        .sheetStyle(style)
    }
}

@MainActor
private class LoginModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    
    var completed: Bool {
        if username.isEmpty || password.isEmpty { return false }
        
        return true
    }
    
    func login() async throws {
        let demoHash = "8c42a34a033fcbfaf9af135ff41c415b55ef444c3f38fb385bbbcba3a07b07b1"
        let usernameHash = SHA256.hash(data: username.data(using: String.Encoding.utf8)!)
        let hashString = usernameHash.map { String(format: "%02hhx", $0) }.joined()
        if hashString == demoHash {
            if let (authTestURL, forumTestURL, curriculumTestURL) = Demo.getDemoURLs() {
                UserDefaults.standard.set(authTestURL.absoluteString, forKey: "fduhole_auth_url")
                UserDefaults.standard.set(forumTestURL.absoluteString, forKey: "fduhole_base_url")
                UserDefaults.standard.set(curriculumTestURL.absoluteString, forKey: "danke_base_url")
                            
                authURL = authTestURL
                forumURL = forumTestURL
                curriculumURL = curriculumTestURL
            }
        }
                
        try await CommunityModel.shared.login(email: username, password: password)
    }
}

// MARK: - Register

struct RegisterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject.Optional private var authModel: AuthenticationModel?
    @StateObject private var model = RegisterModel()
    @State private var showVerificationAlert = false
    @FocusState private var emailFocus: Bool
    @FocusState private var passwordFocus: Bool
    @FocusState private var repeatFocus: Bool
    
    enum SheetType {
        case register, forgetPassword, resetPassword
    }
    
    let type: SheetType
    
    var body: some View {
        Form {
            if type == .register {
                FormTitle(title: String(localized: "Register DanXi Account", bundle: .module),
                          description: String(localized: "Use campus email to register DanXi account.", bundle: .module))
            } else if type == .forgetPassword {
                FormTitle(title: String(localized: "Forget Password", bundle: .module),
                          description: String(localized: "Use campus email to reset password.", bundle: .module))
            } else if type == .resetPassword {
                FormTitle(title: String(localized: "Reset Password", bundle: .module),
                          description: String(localized: "Set a new password for your account.", bundle: .module))
            }
            
            Section {
                LabeledEntry(String(localized: "Email", bundle: .module)) {
                    TextField(String(localized: "Fudan Campus Email", bundle: .module), text: $model.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .focused($emailFocus)
                }
                
                LabeledEntry(String(localized: "Password", bundle: .module)) {
                    SecureField(String(localized: "Required", bundle: .module), text: $model.password)
                        .focused($passwordFocus)
                }
                .showAlert(!passwordFocus && !model.passwordValid)
                
                LabeledEntry(String(localized: "Repeat", bundle: .module)) {
                    SecureField(String(localized: "Required", bundle: .module), text: $model.repeatPassword)
                        .focused($repeatFocus)
                }
                .showAlert(!repeatFocus && !model.repeatValid)
                
                LabeledEntry(String(localized: "Verify", bundle: .module)) {
                    TextField(String(localized: "Required", bundle: .module), text: $model.verificationCode)
                        .keyboardType(.decimalPad)
                    AsyncButton {
                        try await model.sendVerificationCode()
                        showVerificationAlert = true
                    } label: {
                        Text("Get Code", bundle: .module)
                    }
                    .buttonStyle(.borderless)
                    .disabled(model.email.isEmpty)
                }
            } footer: {
                if type == .register {
                    Text("Register Prompt", bundle: .module)
                        .useSafariController()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                AsyncButton {
                    try await model.register(create: type == .register)
                    authModel?.done = true
                    dismiss()
                } label: {
                    Text(type == .register ? "Register" : "Submit", bundle: .module)
                }
                .disabled(!model.completed)
            }
        }
        .alert(String(localized: "Verification Email Sent", bundle: .module), isPresented: $showVerificationAlert) {} message: {
            Text("Check email inbox for verification code, notice that it may be filtered by junk mail", bundle: .module)
        }
    }
}

private class RegisterModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var repeatPassword = ""
    @Published var verificationCode = ""
    
    var passwordValid: Bool {
        password.count >= 8 || password.isEmpty
    }
    
    var repeatValid: Bool {
        repeatPassword == password || repeatPassword.isEmpty
    }
    
    var completed: Bool {
        if email.isEmpty || password.isEmpty || repeatPassword.isEmpty || verificationCode.isEmpty {
            return false
        }
        
        return passwordValid && repeatValid
    }
    
    func sendVerificationCode() async throws {
        try await GeneralAPI.sendVerificationEmail(email: email)
    }
    
    func register(create: Bool) async throws {
        let token = if create {
            try await GeneralAPI.register(email: email, password: password, verification: verificationCode)
        } else {
            try await GeneralAPI.resetPassword(email: email, password: password, verification: verificationCode)
        }
        await CommunityModel.shared.setToken(token: token)
    }
}

#Preview {
    AuthenticationSheet()
}
