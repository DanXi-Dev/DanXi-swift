import Combine
import UserNotifications

/// Collections of app-wide events.
public enum AppEvents {
    /// Navigation triggered by external events, for example, URL scheme.
    public enum Navigation {
        public static let forumHole = PassthroughSubject<Int, Never>()
        public static let forumFloor = PassthroughSubject<Int, Never>()
        public static let campusSection = PassthroughSubject<String, Never>()
    }
    
    /// User taps notification item and open the app. The app should navigate to proper location.
    public static let notification = PassthroughSubject<UNNotificationContent, Never>()
    
    /// User taps "configure notification settings" in system settings. The app should present in-app notification configuration view.
    public static let notificationSettings = PassthroughSubject<UNNotificationContent?, Never>()
}
