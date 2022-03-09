//
//  Settings.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import SwiftUI

struct SettingsPage: View {
    var body: some View {
        Form {
            Section {
                Button("logout") {
                    TreeHoleRepository.shared.token = nil
                    DefaultsManager.shared.fduholeToken = nil
                    AppManager.fduholeAuthenticated.send(false)
                }
            }
        }
        .navigationBarTitle(Text("Settings"))
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        SettingsPage()
    }
}
