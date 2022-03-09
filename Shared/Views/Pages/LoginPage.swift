//
//  LoginPage.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/29.
//

import SwiftUI

struct LoginPage: View {
    @StateObject var loginViewModel: LoginViewModel = LoginViewModel()
    
    var body: some View {
        Form {
            Section(header: Text("fduholeLogin"), footer: Text("fduholeLogin_footer")) {
                TextField("studentId", text: $loginViewModel.username)
                SecureField(NSLocalizedString("pwd", comment: ""), text: $loginViewModel.password)
            }
            if let hasErrorStr = loginViewModel.hasError?.localizedDescription {
                Text(hasErrorStr)
                    .foregroundColor(.red)
            }
            Section {
                Button("loginWithFduhole") {
                    Task.init {
                        await loginViewModel.login()
                    }
                }
                .disabled(loginViewModel.isLoading)
            }
        }
        .navigationTitle("login")
    }
}

struct LoginPage_Previews: PreviewProvider {
    static var previews: some View {
        LoginPage()
    }
}
