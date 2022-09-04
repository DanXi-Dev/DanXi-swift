import SwiftUI

struct LoginPage: View {
    @ObservedObject var model = TreeholeDataModel.shared
    
    @State var username = ""
    @State var password = ""
    @State var loading = false
    
    @State var errorPresenting = false
    @State var errorInfo = ErrorInfo()
    
    @Environment(\.dismiss) private var dismiss
    
    func login() {
        // check info before submit to server
        if username.isEmpty || password.isEmpty {
            errorInfo = ErrorInfo(title: "Incorrect Information", description: "Enter username and password")
            errorPresenting = true
            return
        }
        
        if !username.hasSuffix("fudan.edu.cn") {
            errorInfo = ErrorInfo(title: "Incorrect Information", description: "Invalid username")
            errorPresenting = true
            return
        }
        
        // submitting to server
        loading = true
        Task {
            do {
                try await NetworkRequests.shared.login(username: username, password: password)
                model.loggedIn = true
                loading = false
                dismiss()
            } catch let error as NetworkError {
                switch error {
                case .unauthorized:
                    errorInfo = ErrorInfo(title: "Login Failed", description: "Incorrect username or password")
                default:
                    errorInfo = error.localizedErrorDescription
                }
                
                errorPresenting = true
                loading = false
            } catch {
                loading = false
                print("DANXI-DEBUG: login failed")
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section{
                    TextField("Email", text: $username)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    
                    SecureField(NSLocalizedString("Password", comment: ""), text: $password)
                } footer: {
                    if loading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        
                    }
                }
            }
            .navigationTitle("DanXi Login")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: login) {
                        Text("Login")
                            .bold()
                    }
                        .alert(errorInfo.title, isPresented: $errorPresenting) {
                            Button("OK") { }
                        } message: {
                            Text(errorInfo.description)
                        }
                }
            }
            
        }
    }
}

struct LoginPage_Previews: PreviewProvider {
    static var previews: some View {
        LoginPage()
    }
}
