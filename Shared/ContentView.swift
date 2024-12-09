import SwiftUI
import ViewUtils
import DanXiUI
import FudanKit
import FudanUI
import Utils

@MainActor
struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var model = AppModel()
    @StateObject private var navigator = AppNavigator()
    @StateObject private var tabViewModel = TabViewModel() // an empty object, for environment object to exist
    
    @AppStorage("intro-done") var showIntro = true // shown once
    
    var body: some View {
        WideScreenReader {
            SplitNavigation(screen: $model.screen)
        } narrow: {
            TabNavigation(screen: $model.screen)
        }
        .environmentObject(navigator)
        .environmentObject(model)
        .environmentObject(tabViewModel)
        .onReceive(AppEvents.notification) { content in
            model.screen = .forum
        }
        .onReceive(AppEvents.notificationSettings) { content in
            model.screen = .settings
        }
        .onAppear {
            navigator.isCompactMode = (horizontalSizeClass == .compact)
        }
        .onChange(of: horizontalSizeClass) { horizontalSizeClass in
            navigator.isCompactMode = (horizontalSizeClass == .compact)
        }
        .onOpenURL { url in
            model.handleOpenURL(url: url)
        }
        .sheet(isPresented: $showIntro) {
            IntroSheet()
                .environmentObject(model)
        }
        .onContinueUserActivity("com.fduhole.forum.viewing-hole") { userActivity in
            if let holeId = userActivity.userInfo?["hole-id"] as? Int {
                model.handleNavigation(navigation: .forumHole(holeId: holeId))
            }
        }
    }
}
