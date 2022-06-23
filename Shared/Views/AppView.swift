//
//  AppView.swift
//  DanXi-native
//
//  Created by Singularity on 2022/6/23.
//

import SwiftUI

struct AppView: View {
    @StateObject var viewModel = AppViewModel()
    
    var body: some View {
        content
            .onAppear {
                // TODO: Get User profile and check validity
            }
            .onReceive(AuthManager.AuthUserChanged, perform: {
                let newUser = $0
                if (newUser.token == nil) {
                    viewModel.userState = UserState.none
                } else {
                    viewModel.userState = UserState.authorized(newUser)
                }
            })
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.userState {
        case .none:
            LoginPage()
        case let .authorized(user):
            MainView(authUser: user)
        }
    }
}

struct MainView: View {
    var authUser: User
    
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

final class AppViewModel: ObservableObject {
    @Published var userState: UserState = .none
}
