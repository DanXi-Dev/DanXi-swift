//
//  LoginPage.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/29.
//

import SwiftUI

struct LoginPage: View {
    @EnvironmentObject var accountView: AccountViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var errorString: String?
    @State private var isLoading: Bool = false
    
    func login() async {
        isLoading = true
        errorString = nil
        defer { isLoading = false }
        
        do {
            let token = try await TreeHoleRepository.shared.loginWithUsernamePassword(username: username, password: password)
            accountView.setFduholeAuthenticationStatus(value: true)
            DefaultsManager.shared.fduholeToken = token
        } catch {
            errorString = error.localizedDescription
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("uisLogin")) {
                TextField("studentId", text: $username)
                SecureField(NSLocalizedString("pwd", comment: ""), text: $password)
                if let hasErrorStr = errorString {
                    Text(hasErrorStr)
                        .foregroundColor(.red)
                }
            }
            Section {
                Button {
                    Task.init{
                        await login()
                    }
                } label: {
                    Text("login")
                    if (isLoading) { ProgressView() }
                }
            }
            
            Section(header: Text("fduholeLogin"), footer: Text("fduholeLogin_footer")) {
                Button("loginWithFduhole") {
                    // did tap
                }
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
