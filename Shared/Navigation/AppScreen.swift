import SwiftUI

enum AppScreen: Codable, Hashable, Identifiable, CaseIterable {
    case campus, forum, curriculum, calendar, settings
    
    var id: AppScreen {
        self
    }
}

extension AppScreen {
    var label: some View {
        switch self {
        case .campus:
            Label("Campus.Tab", systemImage: "square.stack")
        case .forum:
            Label("Forum", systemImage: "text.bubble")
        case .curriculum:
            Label("Curriculum", systemImage: "books.vertical")
        case .calendar:
            Label("Calendar", systemImage: "calendar")
        case .settings:
            Label("Settings", systemImage: "gearshape")
        }
    }
    
    // var content: some View
    
    // var detail: some View
}
