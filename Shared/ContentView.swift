import SwiftUI
import ViewUtils
import FudanKit
import FudanUI

@MainActor
struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var model = AppModel()
    @StateObject private var navigator = AppNavigator()
    
    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                TabNavigation(screen: $model.screen)
                    .environmentObject(navigator)
            } else {
                SplitNavigation(screen: $model.screen)
                    .environmentObject(navigator)
            }
        }
        .environmentObject(model)
        .onOpenURL { url in
            model.openURL(url)
        }
        .onReceive(AppModel.notificationPublisher) { content in
            model.screen = .forum
        }
        .onReceive(AppModel.notificationSettingsPublisher) { content in
            model.screen = .settings
        }
        .onAppear {
            navigator.isCompactMode = (horizontalSizeClass == .compact)
        }
        .onChange(of: horizontalSizeClass) { horizontalSizeClass in
            navigator.isCompactMode = (horizontalSizeClass == .compact)
        }
        .sheet(isPresented: $model.showIntro) {
            IntroSheet()
                .environmentObject(model)
        }
    }
}
