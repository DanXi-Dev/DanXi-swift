import SwiftUI

struct THLoginPage: View {
    @Binding var showLoginPage: Bool // passed from caller, exit after successful login
    @State var username = ""
    @State var password = ""
    @State var loading = false
    
    @EnvironmentObject var accountState: THSystem
    
    var body: some View {
        NavigationView {
            Form {
                TextField("email", text: $username)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                
                SecureField(NSLocalizedString("password", comment: ""), text: $password)
            }
            .navigationTitle("fduhole_login_prompt")
            .navigationBarTitleDisplayMode(.inline)
#if !os(watchOS)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") {
                        showLoginPage = false
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("login") {
                        loading = true
                        Task.init {
                            guard let token = await THlogin(username: username, password: password) else {
                                // TODO: warn login failure
                                loading = false
                                return
                            }
                            loading = false
                            accountState.credential = token
                            accountState.isLogged = true
                            showLoginPage = false
                        }
                    }
                    .disabled(loading)
                }
            }
#endif
        }
    }
}


struct THLoginPage_Previews: PreviewProvider {
    static var showLoginPage = false
    
    static var previews: some View {
        THLoginPage(showLoginPage: .constant(true))
    }
}
