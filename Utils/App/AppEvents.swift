import Combine
import UserNotifications

/// Collections of app-wide events.
public enum AppEvents {
    
    /// User taps notification item and open the app. The app should navigate to proper location.
    public static let notification = PassthroughSubject<UNNotificationContent, Never>()
    
    /// User taps "configure notification settings" in system settings. The app should present in-app notification configuration view.
    public static let notificationSettings = PassthroughSubject<UNNotificationContent?, Never>()

    public static let foldedContentSettings = PassthroughSubject<Void, Never>()
}
