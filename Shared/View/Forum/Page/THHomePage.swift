import SwiftUI

struct THHomePage: View {
    @ObservedObject var appModel = DXModel.shared
    @StateObject var model = THNavigationModel()
    
    var body: some View {
        NavigationStack(path: $model.path) {
            LoadingPage(finished: appModel.forumLoaded) {
                try await appModel.loadForum()
            } content: {
                Group {
                    switch model.page {
                    case .browse:
                        THBrowseWrapper()
                    case .favorite:
                        THFavoritesPage()
                    default:
                        Text("TODO")
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        menu
                    }
                }
                .navigationDestination(for: THHole.self) { hole in
                    THHolePage(hole)
                }
                .navigationDestination(for: THHoleLoader.self) { loader in
                    THLoaderPage(loader)
                }
                .navigationDestination(for: THTag.self) { tag in
                    THSearchTagPage(tagname: tag.name)
                }
            }
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
                Label("Notifications", systemImage: "bell")
                    .tag(THPage.notifications)
                Label("Messages", systemImage: "message")
                    .tag(THPage.messages)
                if DXModel.shared.isAdmin {
                    Label("Report", systemImage: "exclamationmark.triangle")
                        .tag(THPage.report)
                }
            }
        } label: {
            Image(systemName: "rectangle.stack")
        }
    }
}
