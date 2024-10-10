import SwiftUI
import FudanUI
import DanXiUI

enum AppScreen: Codable, Hashable, Identifiable, CaseIterable {
    case campus, forum, curriculum, community, innovation, calendar, settings
    
    var id: AppScreen {
        self
    }
}

extension AppScreen {
    var label: some View {
        switch self {
        case .campus:
            Label("Campus", systemImage: "square.stack")
        case .forum:
            Label("Forum", systemImage: "leaf")
        case .curriculum:
            Label("Curriculum", systemImage: "books.vertical")
        case .community:
            Label("Community", systemImage: "bubble")
        case .innovation:
            Label("Innovation", systemImage: "lightbulb.max")
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
            ForumContent()
        case .curriculum:
            CurriculumContent()
        case .community:
            CommunityPage()
        case .innovation:
            EmptyView()
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
            ForumDetail()
        case .curriculum:
            CurriculumDetail()
        case .community:
            EmptyView()
        case .innovation:
            InnovationHomePage()
        case .settings:
            SettingsDetail()
        default:
            EmptyView()
        }
    }
}
