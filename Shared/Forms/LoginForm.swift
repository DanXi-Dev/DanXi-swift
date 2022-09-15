import SwiftUI

struct LoginForm: View {
    @ObservedObject var model = TreeholeDataModel.shared
    
    @State var username = ""
    @State var password = ""
    @State var loading = false
    
    @State var errorPresenting = false
    @State var errorInfo = ""
    
    @Environment(\.dismiss) private var dismiss
    
    func login() {
        if !username.hasSuffix("fudan.edu.cn") {
            errorInfo = NSLocalizedString("Invalid username", comment: "")
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
            } catch NetworkError.unauthorized {
                errorInfo = NSLocalizedString("Incorrect username or password", comment: "")
                errorPresenting = true
                loading = false
            } catch {
                errorInfo = error.localizedDescription
                errorPresenting = true
                loading = false
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section{
                    TextField("Email", text: $username)
                        .keyboardType(.emailAddress)
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
                        .alert("Error", isPresented: $errorPresenting) {
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
        LoginForm()
    }
}
