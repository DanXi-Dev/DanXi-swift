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
            Label("Notifications", systemImage: "bell")
        case .favorite:
            Label("Favorites", systemImage: "star")
        case .subscription:
            Label("Subscription List", systemImage: "eye")
        case .mypost:
            Label("My Post", systemImage: "person")
        case .myreply:
            Label("My Reply", systemImage: "arrowshape.turn.up.left")
        case .history:
            Label("Recent Browsed", systemImage: "clock.arrow.circlepath")
        case .tags:
            Label("All Tags", systemImage: "tag")
        case .report:
            Label("Report", systemImage: "exclamationmark.triangle")
        case .moderate:
            Label("Moderate", systemImage: "video")
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
