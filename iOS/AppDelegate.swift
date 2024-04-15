import UIKit
import UserNotifications
import WatchConnectivity
import CoreTelephony
import IQKeyboardManagerSwift

class AppDelegate: NSObject, UIApplicationDelegate, WCSessionDelegate, UNUserNotificationCenterDelegate, ObservableObject {
    // MARK: - App Delegate
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        IQKeyboardManager.shared.enable = true
        
        // Clear badge on launch
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        // Register for remote notification
        // We receive notifications regardless of whether we have the permission to display them
        // According to https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns
        // > You register your app and receive your device token each time your app launches using Apple-provided APIs.
        Task(priority: .background) { @MainActor in
            application.registerForRemoteNotifications()
        }
        
#if !targetEnvironment(macCatalyst)
        // Activate internet connection
        let cellular = CTCellularData()
        if cellular.restrictedState != .notRestricted {
            Task {
                do {
                    _ = try await URLSession.shared.data(for: URLRequest(url: URL(string: "https://www.fduhole.com/api/")!))
                } catch {
                    
                }
            }
        }
#endif
        
        return true
    }
    
    // MARK: - Notification
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken
                     deviceToken: Data) {
        if let deviceId = UIDevice.current.identifierForVendor {
            DXModel.shared.receiveToken(deviceToken, deviceId)
        } else {
            // According to https://developer.apple.com/documentation/uikit/uidevice/1620059-identifierforvendor
            // > If the value is nil, wait and get the value again later. This happens, for example, after the device has been restarted but before the user has unlocked the device.
            Task(priority: .background) {
                try await Task.sleep(for: .seconds(120))
                // We shall only retry once. If it still fails, we'll simply ignore this
                if let deviceId = UIDevice.current.identifierForVendor {
                    DXModel.shared.receiveToken(deviceToken, deviceId)
                }
            }
        }
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError
                     error: Error) {
        // According to https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns
        // > Registration might fail if the user’s device isn’t connected to the network, if the APNs server is unreachable for any reason, or if the app doesn’t have the proper code-signing entitlement.
        // > When a failure occurs, set a flag and try to register again at a later time.
        Task(priority: .background) {
            try await Task.sleep(for: .seconds(120))
            application.registerForRemoteNotifications()
        }
    }
    
    
    // This function will be called when the app receive notification
    // This override is necessary to display notification while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // show the notification alert (banner), and with sound
        completionHandler([.banner, .sound, .badge])
    }
    
    
    // This function will be called right after user tap on the notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let content = response.notification.request.content
        Task { @MainActor in
            AppModel.notificationPublisher.send(content) // publish event for UI to handle
        }
        completionHandler()
    }
    
    // This function will be called when user taps the link in System Notification Settings
    // It should open the notification settings in our app
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        let content = notification?.request.content
        Task { @MainActor in
            AppModel.notificationSettingsPublisher.send(content)
        }
    }
    
    
    // MARK: - Watch Connectivity
    
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
}
