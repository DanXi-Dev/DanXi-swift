import SwiftUI

struct LoginPage: View {
    @ObservedObject var model = treeholeDataModel
    
    @Binding var showLoginPage: Bool // passed from caller, exit after successful login
    @State var username = ""
    @State var password = ""
    @State var loading = false
    
    func login() {
        loading = true
        Task {
            do {
                try await networks.login(username: username, password: password)
                model.loggedIn = true
                loading = false
                showLoginPage = false
                model.initialFetch()
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
                    TextField("email", text: $username)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    
                    SecureField(NSLocalizedString("password", comment: ""), text: $password)
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
            .navigationTitle("fduhole_login_prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") {
                        showLoginPage = false
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("login", action: login)
                        .disabled(loading)
                }
            }
        }
    }
}

struct LoginPage_Previews: PreviewProvider {
    static var previews: some View {
        LoginPage(showLoginPage: .constant(true))
    }
}
