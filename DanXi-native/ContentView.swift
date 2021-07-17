//
//  ContentView.swift
//  DanXi-native
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
                Text("The Last Tab")
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("settings")
                    }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
