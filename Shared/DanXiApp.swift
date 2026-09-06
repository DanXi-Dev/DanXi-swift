import SwiftUI
import OSLog
import FudanKit
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
        HangDetector.start()
        WebVPNCookieStore.restore()
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
                        WebVPNCookieStore.save()
                    }
                }
        }
    }
}

// MARK: - Temporary hang diagnostics
//
// Watches the main thread from a background thread. When the main thread stops
// responding for `threshold` seconds, this logs a fault and then deliberately
// crashes, so that iOS writes a crash report containing *every* thread's
// backtrace — including the stuck main thread, which is what we actually want.
//
// Where to find the report:
//   Xcode -> Window -> Devices and Simulators -> View Device Logs
//   or on device: Settings -> Privacy & Security -> Analytics & Improvements -> Analytics Data
//
// Remove this once the hang is identified.
enum HangDetector {
    private static let logger = Logger(subsystem: "io.github.danxi-dev.dan-xi", category: "hang")
    private static let lock = NSLock()
    private static var pendingPings = 0

    static func start(threshold: TimeInterval = 8, crashOnHang: Bool = true) {
        let interval: TimeInterval = 1
        let limit = max(1, Int(threshold / interval))

        Thread.detachNewThread {
            Thread.current.name = "HangDetector"
            var lastLoop = Date()

            while true {
                // A long wall-clock gap means the whole process was suspended
                // (e.g. sent to the background), not that the main thread hung.
                let now = Date()
                if now.timeIntervalSince(lastLoop) > interval * 3 {
                    lock.withLock { pendingPings = 0 }
                }
                lastLoop = now

                let outstanding = lock.withLock { () -> Int in
                    pendingPings += 1
                    return pendingPings
                }

                DispatchQueue.main.async {
                    lock.withLock { pendingPings = 0 }
                }

                if outstanding >= limit {
                    logger.fault("Main thread blocked for at least \(outstanding, privacy: .public)s")
                    if crashOnHang {
                        fatalError("HangDetector: main thread blocked for at least \(outstanding)s")
                    }
                }

                Thread.sleep(forTimeInterval: interval)
            }
        }
    }
}
