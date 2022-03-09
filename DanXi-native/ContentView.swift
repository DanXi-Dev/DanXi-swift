//
//  ContentView.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import SwiftUI

struct ContentView: View {
    @State var isFduholeAuthenticated = AppManager.isFduholeAuthenticated()
    
    var body: some View {
        NavigationView {
            if (isFduholeAuthenticated) {
                TabView {
                    TreeHolePage()
                        .tabItem {
                            Image(systemName: "text.bubble")
                            Text("treehole")
                        }
                    SettingsPage()
                        .tabItem {
                            Image(systemName: "gearshape")
                            Text("settings")
                        }
                }
            } else {
                LoginPage()
            }
        }
        .onReceive(AppManager.fduholeAuthenticated, perform: { isFduholeAuthenticated = $0 })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
