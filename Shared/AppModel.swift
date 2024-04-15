import Foundation
import UserNotifications
import Combine
import SwiftUI
import Utils

@MainActor
class AppModel: ObservableObject {
    // publish event when user taps notification, UI should perform navigation
    static let notificationPublisher = PassthroughSubject<UNNotificationContent, Never>()
    static let notificationSettingsPublisher = PassthroughSubject<UNNotificationContent?, Never>()
    
    @AppStorage("intro-done") var showIntro = true // Shown once
    @Published var screen: AppScreen = .campus {
        willSet {
            if screen == newValue {
                switch(screen) {
                case .campus:
                    OnDoubleTapCampusTabBarItem.send()
                case .forum:
                    OnDoubleTapForumTabBarItem.send()
                case .curriculum:
                    OnDoubleTapCurriculumTabBarItem.send()
                case .calendar:
                    OnDoubleTapCalendarTabBarItem.send()
                case .settings:
                    OnDoubleTapSettingsTabBarItem.send()
                }
            }
        }
    }
    
    func openURL(_ url: URL) {
        switch url.host {
        case "settings":
            screen = .settings
        case "campus":
            screen = .campus
        case "forum":
            screen = .forum
        case "calendar":
            screen = .calendar
        case "curriculum":
            screen = .curriculum
        default: break
        }
    }
}
