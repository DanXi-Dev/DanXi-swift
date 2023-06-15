import SwiftUI

struct DXAuthSheet: View {
    @StateObject var model = DXAuthModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            LoginSheet()
        }
        .onChange(of: model.done) { done in
            if done {
                dismiss()
            }
        }
        .environmentObject(model)
    }
}

class DXAuthModel: ObservableObject {
    @Published var done = false
}

// MARK: - Login

fileprivate struct LoginSheet: View {
    @EnvironmentObject var authModel: DXAuthModel
    @StateObject var model = LoginModel()
    @FocusState private var usernameFocus: Bool
    
    var body: some View {
        Form {
            FormTitle(title: "DanXi Account",
                      description: "DanXi account is used to access community services such as Treehole and DanKe.")
            
            Section {
                LabeledEntry("Email") {
                    TextField("Use campus email to login", text: $model.username)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .focused($usernameFocus)
                }
                .showAlert(!usernameFocus && !model.usernameValid)
                
                LabeledEntry("Password") {
                    SecureField("Required", text: $model.password)
                }
            } footer: {
                HStack(spacing: 20) {
                    Spacer()
                    NavigationLink("Register") {
                        RegisterSheet(type: .register)
                    }
                    NavigationLink("Forget Password") {
                        RegisterSheet(type: .forgetPassword)
                    }
                }
                .padding(.top)
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                AsyncButton {
                    try await model.login()
                    authModel.done = true
                } label: {
                    Text("Login")
                }
                .disabled(!model.completed)
            }
        }
    }
}

fileprivate class LoginModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    
    var usernameValid: Bool {
        username.hasSuffix("fudan.edu.cn") || username.isEmpty
    }
    
    var completed: Bool {
        if username.isEmpty || password.isEmpty { return false }
        
        return usernameValid
    }
    
    func login() async throws {
        try await DXModel.shared.login(username: username, password: password)
    }
}


// MARK: - Register

fileprivate struct RegisterSheet: View {
    @EnvironmentObject private var authModel: DXAuthModel
    @StateObject private var model = RegisterModel()
    @State private var showVerificationAlert = false
    @FocusState private var emailFocus: Bool
    @FocusState private var passwordFocus: Bool
    @FocusState private var repeatFocus: Bool
    
    enum SheetType {
        case register, forgetPassword
    }
    
    let type: SheetType
    
    var body: some View {
        Form {
            if type == .register {
                FormTitle(title: "Register DanXi Account",
                          description: "Use campus email to register DanXi account.")
            } else {
                FormTitle(title: "Forget Password",
                          description: "Use campus email to reset password.")
            }
            
            Section {
                LabeledEntry("Email") {
                    TextField("Fudan Campus Email", text: $model.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .focused($emailFocus)
                }
                .showAlert(!emailFocus && !model.emailValid)
                
                LabeledEntry("Password") {
                    SecureField("Required", text: $model.password)
                        .focused($passwordFocus)
                }
                .showAlert(!passwordFocus && !model.passwordValid)
                
                LabeledEntry("Repeat") {
                    SecureField("Required", text: $model.repeatPassword)
                        .focused($repeatFocus)
                }
                .showAlert(!repeatFocus && !model.repeatValid)
                
                LabeledEntry("Verify") {
                    TextField("Required", text: $model.verificationCode)
                        .keyboardType(.decimalPad)
                    AsyncButton {
                        try await model.sendVerificationCode()
                        showVerificationAlert = true
                    } label: {
                        Text("Get Code")
                    }
                    .disabled(!model.emailValid || model.email.isEmpty)
                }
            } footer: {
                if type == .register {
                    Text("Register Prompt")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                AsyncButton {
                    try await model.register(create: type == .register)
                    authModel.done = true
                } label: {
                    Text(type == .register ? "Register" : "Submit")
                }
                .disabled(!model.completed)
            }
        }
        .alert("Verification Email Sent", isPresented: $showVerificationAlert) {
            Button("OK") { }
        } message: {
            Text("Check email inbox for verification code, notice that it may be filtered by junk mail")
        }
    }
}

fileprivate class RegisterModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var repeatPassword = ""
    @Published var verificationCode = ""
    
    var emailValid: Bool {
        email.hasSuffix("fudan.edu.cn") || email.isEmpty
    }
    
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
        
        return emailValid && passwordValid && repeatValid
    }
    
    func sendVerificationCode() async throws {
        try await DXRequests.verifyEmail(email: email)
    }
    
    func register(create: Bool) async throws {
        try await DXModel.shared.resetPassword(email: email,
                                               password: password,
                                               verification: verificationCode,
                                               create: create)
    }
}

// MARK: - Components

fileprivate struct LabeledEntry<Content: View>: View {
    let label: LocalizedStringKey
    var showAlert = false
    let content: Content
    
    init(_ label: LocalizedStringKey,
         @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.content = content()
    }
    
    func showAlert(_ showAlert: Bool) -> LabeledEntry {
        var entry = self
        entry.showAlert = showAlert
        return entry
    }
    
    var body: some View {
        LabeledContent {
            HStack {
                content
                if showAlert {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.red)
                }
            }
        } label: {
            HStack {
                Text(label)
                    .bold()
                Spacer()
            }
            .frame(maxWidth: 90)
        }
        .listRowBackground(Color.separator.opacity(0.2))
    }
}

fileprivate struct FormTitle: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    
    var body: some View {
        Section {
            HStack {
                Spacer()
                VStack(spacing: 10) {
                    Text(title)
                        .font(.title)
                        .bold()
                    Text(description)
                }
                Spacer()
            }
            .listRowBackground(Color.clear)
        }
    }
}
