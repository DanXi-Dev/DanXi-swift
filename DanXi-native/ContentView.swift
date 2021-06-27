//
//  ContentView.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardPage()
                .tabItem {
                    Image(systemName: "1.square.fill")
                    Text("Dashboard")
                }
            TreeHolePage()
                .tabItem {
                    Image(systemName: "2.square.fill")
                    Text("Tree Hole")
                }
            Text("The Last Tab")
                .tabItem {
                    Image(systemName: "3.square.fill")
                    Text("Settings")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
