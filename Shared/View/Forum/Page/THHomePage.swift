import SwiftUI
import ViewUtils
import Utils

struct THHomePage: View {
    @ObservedObject private var appModel = DXModel.shared
    @ObservedObject private var forumModel = THModel.shared
    @EnvironmentObject private var navigator: AppNavigator
    
    var body: some View {
        AsyncContentView(finished: forumModel.loaded, refreshable: false) { _ in
            _ = try await appModel.loadUser() // load user first to prevent concurrently refresh token
            try await forumModel.loadAll()
        } content: {
            THBrowseWrapper()
        }
        .onReceive(AppEvents.notification) { _ in
            navigator.pushContent(value: ForumSection.notifications)
        }
        .navigationTitle("Forum")
    }
}
