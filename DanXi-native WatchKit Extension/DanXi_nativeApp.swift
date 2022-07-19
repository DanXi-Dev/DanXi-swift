//
//  DanXi_nativeApp.swift
//  DanXi-native WatchKit Extension
//
//  Created by Kavin Zhao on 2021/6/26.
//

import SwiftUI

@main
struct DanXi_nativeApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
