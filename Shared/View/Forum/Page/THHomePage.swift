import SwiftUI

struct THHomePage: View {
    @ObservedObject private var appModel = DXModel.shared
    @ObservedObject private var forumModel = THModel.shared
    @StateObject private var model = THNavigator()
    
    var body: some View {
        AsyncContentView(finished: forumModel.loaded) {
            try await forumModel.loadAll()
            _ = try await appModel.loadUser()
        } content: {
            NavigationStack(path: $model.path) {
                Group {
                    switch model.page {
                    case .browse:
                        THBrowseWrapper()
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
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        menu
                    }
                }
                .navigationDestination(for: THHole.self) { hole in
                    THHolePage(hole)
                        .environmentObject(model) // prevent crash on NavigationSplitView, reason unknown
                }
                .navigationDestination(for: THHoleLoader.self) { loader in
                    THLoaderPage(loader)
                        .environmentObject(model) // prevent crash on NavigationSplitView, reason unknown
                }
                .navigationDestination(for: THTag.self) { tag in
                    THSearchTagPage(tagname: tag.name)
                        .environmentObject(model) // prevent crash on NavigationSplitView, reason unknown
                }
            }
        }
        .environmentObject(model)
        .onOpenURL { url in
            model.openURL(url)
        }
    }
    
    private var menu: some View {
        Menu {
            Picker("Page Selection", selection: $model.page) {
                Label("Tree Hole", systemImage: "doc.plaintext")
                    .tag(THPage.browse)
                Label("Favorites", systemImage: "star")
                    .tag(THPage.favorite)
                Label("My Post", systemImage: "person")
                    .tag(THPage.mypost)
                Label("Recent Browsed", systemImage: "clock.arrow.circlepath")
                    .tag(THPage.history)
                Label("All Tags", systemImage: "tag")
                    .tag(THPage.tags)
                Label("Notifications", systemImage: "bell")
                    .tag(THPage.notifications)
                if appModel.isAdmin {
                    Label("Report", systemImage: "exclamationmark.triangle")
                        .tag(THPage.report)
                }
            }
        } label: {
            Image(systemName: "rectangle.stack")
        }
    }
}
