import SwiftUI
import DanXiUI
import DanXiKit
import ViewUtils
import Utils

@main
struct DanXiApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    #if os(iOS)
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #endif
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task(priority: .background) {
                    ConfigurationCenter.initialFetch()
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .background {
                        Proxy.shared.outsideCampus = false
                    }
                }
        }
    }
}
