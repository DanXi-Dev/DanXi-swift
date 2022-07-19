import SwiftUI

struct TreeHoleLoginPage: View {
    @Binding var showLoginPage: Bool
    @EnvironmentObject private var appModel: AppModel
    @StateObject var loginViewModel: LoginViewModel = LoginViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("邮箱", text: $loginViewModel.username)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    
                    SecureField(NSLocalizedString("密码", comment: ""), text: $loginViewModel.password)
                }
                
                
                if let hasErrorStr = loginViewModel.hasError?.localizedDescription {
                    Section {
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
            .navigationTitle("登录旦夕")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showLoginPage = false
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("登录") {
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
