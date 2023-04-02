import Foundation

@MainActor
class AppModel: ObservableObject {
    @Published var section = AppSection.campus
    
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
