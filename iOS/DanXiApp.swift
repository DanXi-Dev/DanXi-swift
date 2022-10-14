import SwiftUI
import UserNotifications
import WatchConnectivity

@main
struct DanXiApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    init() {
        
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, WCSessionDelegate, UNUserNotificationCenterDelegate, ObservableObject {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
    }
    
    func sendString(text: String) {
        let session = WCSession.default;
        if (WCSession.isSupported()) {
            DispatchQueue.main.async {
                session.sendMessage(["token": text], replyHandler: nil)
            }
        }
    }
    
    func application(_ application: UIApplication,
                              didRegisterForRemoteNotificationsWithDeviceToken
                              deviceToken: Data) {
        let token: String = deviceToken.map { String(format: "%.2hhx", $0) }.joined()
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "" //TODO: How to handle nil UUID?
        
        /* Send token to FDUHole */
        DXNetworks.shared.cacheOrUploadAPNSKey(token: token, deviceId: deviceId)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    
    func application(_ application: UIApplication,
                              didFailToRegisterForRemoteNotificationsWithError
                              error: Error) {
        //TODO: Retry?
    }
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        // Clear badge on launch
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound],
            completionHandler: {_, _ in })
        
        
        // Request online content to activate internet privilege
        Task {
            do {
                _ = try await URLSession.shared.data(for: URLRequest(url: URL(string: "https://www.fduhole.com/api/")!))
            }
        }
        
        return true
    }
    
    // This function will be called when the app receive notification
    // This override is necessary to display notification while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // show the notification alert (banner), and with sound
        completionHandler([.banner, .sound, .badge])
    }
    
    // This function will be called right after user tap on the notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
