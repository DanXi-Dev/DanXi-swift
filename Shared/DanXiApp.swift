import SwiftUI
import DanXiUI
import DanXiKit
import ViewUtils
import Utils
import TipKit

@main
struct DanXiApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    #if os(iOS)
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #endif

    init() {
        CookieStore.restore() // restore the persisted Fudan/WebVPN session before any request
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task(priority: .background) {
                    if #available(iOS 17.0, *) {
                        try? Tips.configure([
                            .displayFrequency(.weekly)
                        ])
                    }
                    ConfigurationCenter.initialFetch()
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .background {
                        Proxy.shared.outsideCampus = false
                        CookieStore.save() // persist the session so the next cold start can skip login
                    }
                }
        }
    }
}
