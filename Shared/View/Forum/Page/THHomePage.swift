import SwiftUI
import ViewUtils
import BetterSafariView

struct THHomePage: View {
    @ObservedObject private var appModel = DXModel.shared
    @ObservedObject private var forumModel = THModel.shared
    @State private var openURL: URL? = nil
    
    var body: some View {
        AsyncContentView(finished: forumModel.loaded, refreshable: false) { _ in
            _ = try await appModel.loadUser() // load user first to prevent concurrently refresh token
            try await forumModel.loadAll()
        } content: {
            THBrowseWrapper()
        }
        .navigationTitle("Forum")
        #if !targetEnvironment(macCatalyst)
        .environment(\.openURL, OpenURLAction { url in
            openURL = url
            return .handled
        })
        .safariView(item: $openURL) { link in
            SafariView(url: link)
        }
        #endif
    }
}
