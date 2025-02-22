import DanXiKit
import SwiftUI
import ViewUtils

struct PostSheet: View {
    @ObservedObject private var profileStore = ProfileStore.shared
    @ObservedObject private var divisionStore = DivisionStore.shared
    @EnvironmentObject private var navigator: AppNavigator
    
    @State var divisionId: Int
    @State private var content = ""
    @State private var tags: [String] = []
    @State private var specialTag: String = ""
    @State private var hasSubmitted = false
    
    init(divisionId: Int) {
        self.divisionId = divisionId
    }
    
    init(divisionId: Int, content: String = "", tags: [String] = []) {
        self._content = State(initialValue: content)
        self._tags = State(initialValue: tags)
        self.divisionId = divisionId
    }
    
    var body: some View {
        Sheet(String(localized: "New Post", bundle: .module)) {
            let hole = try await ForumAPI.createHole(content: content, divisionId: divisionId, tags: tags, specialTag: specialTag)
            hasSubmitted = true
            await DraftboxStore.shared.deletePostDraft()
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
            
            if profileStore.isAdmin {
                Section {
                    TextField(String(localized: "Special Tag", bundle: .module), text: $specialTag)
                } header: {
                    Text("Admin Actions", bundle: .module)
                }
            }
            
            ForumEditor(content: $content, initiallyFocused: false)
        }
        .completed(!tags.isEmpty && !content.isEmpty)
        .onDisappear {
            Task {
                if !hasSubmitted {
                    DraftboxStore.shared.addPostDraft(content: content, tags: tags)
                }
            }
        }
    }
}
