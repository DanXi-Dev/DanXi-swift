import Foundation
import UserNotifications
import Combine
import FudanKit
import SwiftUI
import Utils

class AppModel: ObservableObject {
    // publish event when user taps notification, UI should perform navigation
    static let notificationPublisher = PassthroughSubject<UNNotificationContent, Never>()
    static let notificationSettingsPublisher = PassthroughSubject<UNNotificationContent?, Never>()
    
    @AppStorage("intro-done") var showIntro = true // Shown once
    @Published var screen: AppScreen {
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
    
    @MainActor
    init() {
        if CampusModel.shared.loggedIn {
            screen = .campus
        } else if DXModel.shared.isLogged {
            screen = .forum
        } else {
            screen = .settings
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
