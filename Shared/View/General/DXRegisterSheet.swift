import SwiftUI

// TODO: check password strench (8 characters) & check email format

struct DXRegisterSheet: View {
    let create: Bool
    
    @State var email = ""
    @State var password = ""
    @State var confirm = ""
    @State var verification = ""
    
    @State var sendingCode = false
    @State var loading = false
    
    @State var errorInfo = ""
    @State var showErrorAlert = false
    @State var showEmailAlert = false
    @State var showVerificationAlert = false
    @State var showPasswordAlert = false
    
    var dismiss: DismissAction? // passed from Login Form, dismiss all
    
    init(create: Bool) {
        self.create = create
    }
    
    init(create: Bool, dismiss: DismissAction) {
        self.create = create
        self.dismiss = dismiss
    }
    
    func register() {
        Task {
            if !email.hasSuffix("fudan.edu.cn") {
                showEmailAlert = true
                return
            }
            
            if password != confirm {
                showPasswordAlert = true
                return
            }
            
            do {
                try await AuthDelegate.shared.register(email: email,
                                                       password: password,
                                                       verification: verification,
                                                       create: create)
                if let dismiss = dismiss { dismiss() }
            } catch {
                errorInfo = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
    
    func sendVerificationCode() {
        Task {
            if !email.hasSuffix("fudan.edu.cn") {
                showEmailAlert = true
                return
            }
            
            sendingCode = true
            do {
                try await AuthReqest.verifyEmail(email: email)
                showVerificationAlert = true
                sendingCode = false
            } catch {
                errorInfo = error.localizedDescription
                showErrorAlert = true
                sendingCode = false
            }
        }
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                SecureField("Confirm Password", text: $confirm)
                
                HStack {
                    TextField("Verification Code", text: $verification)
                        .keyboardType(.decimalPad)
                    
                    if sendingCode {
                        ProgressView()
                    } else {
                        Button("Get Verification Code") {
                            sendVerificationCode()
                        }
                        .disabled(email.isEmpty)
                        .buttonStyle(.borderless)
                    }
                }
            } footer: {
                if create {
                    Text("Register Prompt")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if loading {
                    ProgressView()
                } else {
                    Button(create ? "Register" : "Reset Password") {
                        register()
                    }
                    .disabled(email.isEmpty || password.isEmpty || confirm.isEmpty || verification.isEmpty)
                }
            }
        }
        .alert("Password Not Match", isPresented: $showPasswordAlert) {
            Button("OK") { }
        } message: {
            Text("Password input not match, please check your input")
        }
        .alert("Email Invalid", isPresented: $showEmailAlert) {
            Button("OK") { }
        } message: {
            Text("Use Fudan university email address")
        }
        .alert("Verification Email Sent", isPresented: $showVerificationAlert) {
            Button("OK") { }
        } message: {
            Text("Check email inbox for verification code, notice that it may be filtered by junk mail")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorInfo)
        }
    }
}

struct DXRegisterSheet_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DXRegisterSheet(create: true)
        }
    }
}
