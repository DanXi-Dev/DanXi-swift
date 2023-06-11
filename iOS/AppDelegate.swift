import UIKit
import UserNotifications
import WatchConnectivity
import CoreTelephony

class AppDelegate: NSObject, UIApplicationDelegate, WCSessionDelegate, UNUserNotificationCenterDelegate, ObservableObject {
    // MARK: - App Delegate
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        
        // Clear badge on launch
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .provisional]) { granted, error in
            if granted || error == nil {
                Task { @MainActor in
                    application.registerForRemoteNotifications()
                }
            }
        }
        
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
        
        return true
    }
    
    // MARK: - Notification
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken
                     deviceToken: Data) {
        if let deviceId = UIDevice.current.identifierForVendor {
            DXModel.shared.receiveToken(deviceToken, deviceId)
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
        // TODO: process notification data and perform navigation
        
        /*
         let userInfo = response.notification.request.content.userInfo
         let dict: [AnyHashable: Any] = userInfo["items"][0] //not sure if you would need explicit type casting here, cant debug as I dont have actual object
         do {
             let jsonData = try JSONSerialization.data(withJSONObject: dict)
             let item = try JSONDecoder().decode(Item.self, from: jsonData)
             //now access item
         }
         catch {
             print(error)
         }
         */
        completionHandler()
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
