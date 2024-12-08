import SwiftUI
import ViewUtils
import FudanKit
import FudanUI
import Utils

@MainActor
struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var model = AppModel()
    @StateObject private var navigator = AppNavigator()
    
    var body: some View {
        WideScreenReader {
            SplitNavigation(screen: $model.screen)
        } narrow: {
            TabNavigation(screen: $model.screen)
        }
        .environmentObject(navigator)
        .environmentObject(model)
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
        .sheet(isPresented: $model.showIntro) {
            IntroSheet()
                .environmentObject(model)
        }
        .onContinueUserActivity("io.github.danxi-dev.dan-xi.viewing-hole") { userActivity in
            if let holeId = userActivity.userInfo?["hole-id"] as? Int {
                model.handleNavigation(navigation: .forumHole(holeId: holeId))
            }
        }
    }
}
