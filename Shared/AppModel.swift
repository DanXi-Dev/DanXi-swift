import Foundation
import UserNotifications
import Combine
import FudanKit
import DanXiUI
import SwiftUI
import Utils

class AppModel: ObservableObject {
    @AppStorage("intro-done") var showIntro = true // Shown once
    @Published var screen: AppScreen {
        willSet {
            if screen == newValue {
                switch(screen) {
                case .campus:
                    AppEvents.TabBarTapped.campus.send()
                case .forum:
                    AppEvents.TabBarTapped.forum.send()
                case .curriculum:
                    AppEvents.TabBarTapped.curriculum.send()
                case .calendar:
                    AppEvents.TabBarTapped.calendar.send()
                case .settings:
                    AppEvents.TabBarTapped.settings.send()
                }
            }
        }
    }
    
    @MainActor
    init() {
        if CampusModel.shared.loggedIn {
            screen = .campus
        } else if CommunityModel.shared.loggedIn {
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
