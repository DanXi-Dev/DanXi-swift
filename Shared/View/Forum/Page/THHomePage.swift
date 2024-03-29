import SwiftUI

struct THHomePage: View {
    @ObservedObject private var appModel = DXModel.shared
    @ObservedObject private var forumModel = THModel.shared
    @StateObject private var navigator = THNavigator()
    
    var body: some View {
        var userId: String {
            appModel.user?.id != nil ? String(appModel.user!.id) : ""
        }
        AsyncContentView(finished: forumModel.loaded) {
            _ = try await appModel.loadUser() // load user first to prevent concurrently refresh token
            try await forumModel.loadAll()
        } content: {
            NavigationStack(path: $navigator.path) {
                THBrowseWrapper()
                    .navigationDestination(for: THHole.self) { hole in
                        THHolePage(hole)
                            .environmentObject(navigator) // prevent crash on NavigationSplitView, reason unknown
                    }
                    .navigationDestination(for: THHoleLoader.self) { loader in
                        THLoaderPage(loader)
                            .environmentObject(navigator) // prevent crash on NavigationSplitView, reason unknown
                    }
                    .navigationDestination(for: THTag.self) { tag in
                        THSearchTagPage(tagname: tag.name)
                            .environmentObject(navigator) // prevent crash on NavigationSplitView, reason unknown
                    }
                    .navigationDestination(for: THPage.self) { page in
                        THSection(page: page)
                    }
            }
            .watermark(content: userId, opacity: 0.03)
        }
        .environmentObject(navigator)
        .onOpenURL { url in
            navigator.openURL(url)
        }
        .onReceive(AppModel.notificationPublisher) { content in
            navigator.path.removeLast(navigator.path.count)
            navigator.path.append(THPage.notifications)
        }
    }
}

fileprivate struct THSection: View {
    let page: THPage
    
    var body: some View {
        switch page {
        case .favorite:
            THFavoritesPage()
        case .subscription:
            THSubscriptionPage()
        case .mypost:
            THMyPostPage()
        case .myreply:
            THMyReplyPage()
        case .tags:
            THTagsPage()
        case .history:
            THBrowseHistoryPage()
        case .report:
            THReportPage()
        case .notifications:
            THNotificationPage()
        case .moderate:
            THModeratePage()
        }
    }
}
