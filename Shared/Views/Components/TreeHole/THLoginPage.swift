import SwiftUI

struct THLoginPage: View {
    @EnvironmentObject var dataModel: THDataModel
    
    @Binding var showLoginPage: Bool // passed from caller, exit after successful login
    @State var username = ""
    @State var password = ""
    @State var loading = false
    
    func login() {
        loading = true
        Task {
            if await dataModel.login(username: username, password: password) {
                showLoginPage = false
            } else {
                // TODO: alert user
            }
            
            loading = false
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
                }
                
                if loading {
                    Section{
                        ProgressView()
                    }
                }
                
#if os(watchOS)
                Section{
                    Button("login") {
                        login()
                    }
                    .disabled(loading)
                    Button("cancel") {
                        showLoginPage = false
                    }
                }
#endif
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
                    Button("login", action: login)
                        .disabled(loading)
                }
            }
#endif
        }
    }
}


struct THLoginPage_Previews: PreviewProvider {
    static let dataModel = THDataModel()
    
    static var previews: some View {
        THLoginPage(showLoginPage: .constant(true))
            .environmentObject(dataModel)
    }
}
