import SwiftUI
import ViewUtils
import Utils

@main
struct DanXiApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #endif
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task(priority: .background) {
                    ConfigurationCenter.initialFetch()
                }
        }
    }
}


