//
//  ContentView.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject var accountView: AccountViewModel = AccountViewModel()
    
    func initializeAccountView() {
        if let fduholeToken = DefaultsManager.shared.fduholeToken {
            accountView.setFduholeAuthenticationStatus(value: true)
            TreeHoleRepository.shared.setToken(token: fduholeToken)
        }
    }
    
    var body: some View {
        NavigationView {
            if (accountView.isFduholeAuthenticated) {
                TabView {
                    TreeHolePage()
                        .tabItem {
                            Image(systemName: "text.bubble")
                            Text("treehole")
                        }
                    Text("The Last Tab")
                        .tabItem {
                            Image(systemName: "gearshape")
                            Text("settings")
                        }
                }
            } else {
                LoginPage()
            }
        }
        .onAppear(perform: initializeAccountView)
        .environmentObject(accountView)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
