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
            if #available(iOS 17.0, *) {
                ContentView()
                    .task(priority: .background) {
                        ConfigurationCenter.initialFetch()
                    }
                    .onChange(of: scenePhase) { oldPhase, newPhase in
                        if oldPhase == .background {
                            // Application is resuming from background
                            // The two other states, active and inactive, should both be treated as running in foreground
                            ProxySettings.shared.enableProxy = false
                            // TODO: refresh outdated homescreen cards
                        }
                    }
            } else {
                ContentView()
                    .task(priority: .background) {
                        ConfigurationCenter.initialFetch()
                    }
            }
        }
    }
}
