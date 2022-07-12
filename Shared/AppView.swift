//
//  AppView.swift
//  DanXi-native
//
//  Created by Singularity on 2022/6/23.
//

import SwiftUI

struct AppView: View {
    @StateObject var appModel = AppModel()
    
    var body: some View {
        content
            .onAppear {
                // TODO: Get User profile and check validity
            }
            .environmentObject(appModel)
    }
    
    @ViewBuilder
    private var content: some View {
        switch appModel.userCredential {
        case nil:
            LoginPage()
        default:
            MainView()
        }
    }
}

struct MainView: View {
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
        }
    }
}
