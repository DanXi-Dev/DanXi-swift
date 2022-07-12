//
//  ContentView.swift
//  DanXi-native WatchKit Extension
//
//  Created by Kavin Zhao on 2021/6/26.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        NavigationView {
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
            LoginPage()
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
