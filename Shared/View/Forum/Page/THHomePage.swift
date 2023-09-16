import SwiftUI

struct THHomePage: View {
    @ObservedObject private var appModel = DXModel.shared
    @ObservedObject private var forumModel = THModel.shared
    @StateObject private var navigator = THNavigator()
    
    var body: some View {
        AsyncContentView(finished: forumModel.loaded) {
            try await forumModel.loadAll()
            _ = try await appModel.loadUser()
        } content: {
            NavigationStack(path: $navigator.path) {
                THBrowseWrapper()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            menu
                        }
                    }
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
    
    private var menu: some View {
        Menu {
            Button {
                navigator.path.append(THPage.favorite)
            } label: {
                Label("Favorites", systemImage: "star")
            }
            
            Button {
                navigator.path.append(THPage.mypost)
            } label: {
                Label("My Post", systemImage: "person")
            }
            
            Button {
                navigator.path.append(THPage.history)
            } label: {
                Label("Recent Browsed", systemImage: "clock.arrow.circlepath")
            }
            
            Button {
                navigator.path.append(THPage.tags)
            } label: {
                Label("All Tags", systemImage: "tag")
            }
            
            Button {
                navigator.path.append(THPage.notifications)
            } label: {
                Label("Notifications", systemImage: "bell")
            }
            
            if appModel.isAdmin {
                Button {
                    navigator.path.append(THPage.report)
                } label: {
                    Label("Report", systemImage: "exclamationmark.triangle")
                }
            }
        } label: {
            Image(systemName: "rectangle.stack")
        }
    }
}

fileprivate struct THSection: View {
    let page: THPage
    
    var body: some View {
        switch page {
        case .favorite:
            THFavoritesPage()
        case .mypost:
            THMyPostPage()
        case .tags:
            THTagsPage()
        case .history:
            THBrowseHistoryPage()
        case .report:
            THReportPage()
        case .notifications:
            THNotificationPage()
        }
    }
}
