import SwiftUI

enum ForumSection: Int, Identifiable, CaseIterable {
    case notifications, favorite, subscription, mypost, myreply, history, tags
    case report, moderate
    
    static let userFeatures: [ForumSection] = [.notifications, .favorite, .subscription, .mypost, .myreply, .history, .tags]
    static let adminFeatures: [ForumSection] = [.report, .moderate]
    
    var id: ForumSection {
        self
    }
}

extension ForumSection {
    var label: some View {
        switch self {
        case .notifications:
            Label(String(localized: "Notifications", bundle: .module), systemImage: "bell")
        case .favorite:
            Label(String(localized: "Favorites", bundle: .module), systemImage: "star")
        case .subscription:
            Label(String(localized: "Subscription List", bundle: .module), systemImage: "eye")
        case .mypost:
            Label(String(localized: "My Post", bundle: .module), systemImage: "person")
        case .myreply:
            Label(String(localized: "My Reply", bundle: .module), systemImage: "arrowshape.turn.up.left")
        case .history:
            Label(String(localized: "Recent Browsed", bundle: .module), systemImage: "clock.arrow.circlepath")
        case .tags:
            Label(String(localized: "All Tags", bundle: .module), systemImage: "tag")
        case .report:
            Label(String(localized: "Report", bundle: .module), systemImage: "exclamationmark.triangle")
        case .moderate:
            Label(String(localized: "Moderate", bundle: .module), systemImage: "video")
        }
    }
    
    @ViewBuilder
    var destination: some View {
        switch self {
        case .favorite:
            FavoritePage()
        case .subscription:
            SubscriptionPage()
        case .mypost:
            MyPostPage()
        case .myreply:
            MyReplyPage()
        case .tags:
            TagsPage()
        case .history:
            BrowseHistoryPage()
        case .report:
            ReportPage()
        case .notifications:
            NotificationPage()
        case .moderate:
            ModeratePage()
        }
    }
}
