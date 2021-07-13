//
//  LoginPage.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/29.
//

import SwiftUI

struct LoginPage: View {
    @State var username = ""
    @State var password = ""
    
    var body: some View {
        Form {
            Section(header: Text("uisLogin")) {
                TextField("studentId", text: $username)
                SecureField(NSLocalizedString("pwd", comment: ""), text: $password)
            }
            Section {
                Button("login") {
                    
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
