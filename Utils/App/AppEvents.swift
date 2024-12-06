import Combine
import UserNotifications

/// Collections of app-wide events.
public enum AppEvents {
    /// User double-taps tab bar item. Navigation stack should pop to root.
    public enum TabBarTapped {
        public static let campus = PassthroughSubject<Void, Never>()
        public static let forum = PassthroughSubject<Void, Never>()
        public static let calendar = PassthroughSubject<Void, Never>()
        public static let curriculum = PassthroughSubject<Void, Never>()
        public static let settings = PassthroughSubject<Void, Never>()
    }
    
    /// User double-taps tab bar item and the navigation stack is already empty, the view should scroll to top.
    public enum ScrollToTop {
        public static let campus = PassthroughSubject<Void, Never>()
        public static let forum = PassthroughSubject<Void, Never>()
        public static let calendar = PassthroughSubject<Void, Never>()
        public static let curriculum = PassthroughSubject<Void, Never>()
        public static let settings = PassthroughSubject<Void, Never>()
    }
    
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
