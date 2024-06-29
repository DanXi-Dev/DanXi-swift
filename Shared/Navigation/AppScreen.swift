import SwiftUI
import FudanUI
import DanXiUI

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
            Label("Forum", systemImage: "leaf")
        case .curriculum:
            Label("Curriculum", systemImage: "books.vertical")
        case .calendar:
            Label("Calendar", systemImage: "calendar")
        case .settings:
            Label("Settings", systemImage: "gearshape")
        }
    }
    
    @ViewBuilder
    var content: some View {
        switch self {
        case .campus:
            CampusContent()
        case .forum:
            DanXiUI.ForumContent()
        case .curriculum:
            DanXiUI.CurriculumContent()
        case .calendar:
            NavigationStack {
                CoursePage()
            }
        case .settings:
            SettingsContent()
        }
    }
    
    @ViewBuilder
    var detail: some View {
        switch self {
        case .campus:
            CampusDetail()
        case .forum:
            DanXiUI.ForumDetail()
        case .curriculum:
            DanXiUI.CurriculumDetail()
        case .settings:
            SettingsDetail()
        default:
            EmptyView()
        }
    }
}
