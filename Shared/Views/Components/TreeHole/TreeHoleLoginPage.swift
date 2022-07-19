import SwiftUI

struct TreeHoleLoginPage: View {
    @Binding var showLoginPage: Bool
    @EnvironmentObject private var appModel: AppModel
    @StateObject var loginViewModel: LoginViewModel = LoginViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section("fduholeAccount") {
                    TextField("email", text: $loginViewModel.username)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    
                    SecureField("pwd", text: $loginViewModel.password)
                }
                
                
                if let hasErrorStr = loginViewModel.hasError?.localizedDescription {
                    Section("error") {
                        Text(hasErrorStr)
                            .foregroundColor(.red)
                    }
                }
                
                if loginViewModel.isLoading {
                    Section {
                        ProgressView()
                    }
                }
            }
            .navigationTitle("fduholeAuth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") {
                        showLoginPage = false
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("login") {
                        Task.init {
                            guard let jwt = await loginViewModel.login() else {
                                return
                            }
                            showLoginPage = false
                            appModel.userCredential = jwt
                        }
                    }
                    .disabled(loginViewModel.isLoading)
                }
            }
            
        }
        
    }
}


struct TreeHoleLoginPage_Previews: PreviewProvider {
    static var showLoginPage = false
    
    static var previews: some View {
        TreeHoleLoginPage(showLoginPage: .constant(true))
    }
}
