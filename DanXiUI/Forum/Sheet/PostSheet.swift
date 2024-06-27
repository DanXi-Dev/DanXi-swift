import SwiftUI
import ViewUtils
import DanXiKit

struct PostSheet: View {
    @ObservedObject private var divisionStore = DivisionStore.shared
    @EnvironmentObject private var navigator: AppNavigator
    
    @State var divisionId: Int
    @State private var content = ""
    @State private var tags: [String] = []
    
    var body: some View {
        Sheet(String(localized: "New Post", bundle: .module)) {
            let hole = try await ForumAPI.createHole(content: content, divisionId: divisionId, tags: tags)
            navigator.pushDetail(value: hole, replace: true) // navigate to hole page
            
            Task {
                try? await FavoriteStore.shared.refreshFavoriteIds()
                try? await SubscriptionStore.shared.refreshSubscriptionIds()
            }
        } content: {
            Section {
                Picker(selection: $divisionId,
                       label: Label(String(localized: "Select Division", bundle: .module), systemImage: "rectangle.3.group")) {
                    ForEach(divisionStore.divisions) { division in
                        Text(division.name).tag(division.id)
                    }
                }
                .labelStyle(.titleOnly)
            }
            
            Section {
                TagEditor($tags, maxSize: 5)
            } header: {
                Text("Tags", bundle: .module)
            }
            
            ForumEditor(content: $content, initiallyFocused: false)
        }
        .completed(!tags.isEmpty && !content.isEmpty)
        .warnDiscard(!tags.isEmpty || !content.isEmpty)
    }
}
