//
//  LoginPage.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/29.
//

import SwiftUI

struct LoginPage: View {
    @EnvironmentObject private var appModel: AppModel
    @StateObject var loginViewModel: LoginViewModel = LoginViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("fduholeLogin"), footer: Text("fduholeLogin_footer")) {
                    TextField("studentId", text: $loginViewModel.username)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    SecureField(NSLocalizedString("pwd", comment: ""), text: $loginViewModel.password)
                }
                if let hasErrorStr = loginViewModel.hasError?.localizedDescription {
                    Text(hasErrorStr)
                        .foregroundColor(.red)
                }
                if loginViewModel.isLoading {
                    ProgressView()
                }
                Section {
                    Button("loginWithFduhole") {
                        Task.init {
                            guard let jwt = await loginViewModel.login() else { return }
                            appModel.userCredential = jwt
                        }
                    }
                    .disabled(loginViewModel.isLoading)
                }
            }
            .navigationTitle("login")
        }
    }
}

struct LoginPage_Previews: PreviewProvider {
    static var previews: some View {
        LoginPage()
    }
}
