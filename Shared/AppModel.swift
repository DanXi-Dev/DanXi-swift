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
    @Published var section: AppSection = .campus {
        willSet {
            if section == newValue {
                switch(section) {
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
            section = .settings
        case "campus":
            section = .campus
        case "forum":
            section = .forum
        case "calendar":
            section = .calendar
        case "curriculum":
            section = .curriculum
        default: break
        }
    }
}

enum AppSection {
    case campus, forum, curriculum, calendar, settings
}
