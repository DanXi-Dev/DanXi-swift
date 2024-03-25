import SwiftUI

struct THPostSheet: View {
    @EnvironmentObject private var navigator: THNavigator
    @ObservedObject private var appModel = THModel.shared
    @State var divisionId: Int
    @AppStorage("post-content") private var content = ""
    @AppStorage("post-tag") private var tags: [String] = []
    
    private func suggestTags() {
        let input = content.stripToNLProcessableString()
        guard let predictedTags = TagPredictor.shared?.suggest(input) else { return }
        withAnimation {
            tags = predictedTags
        }
    }
    
    var body: some View {
        Sheet("New Post") {
            let hole = try await THRequests.createHole(
                content: content,
                divisionId: divisionId,
                tags: tags)
            
            // reset stashed draft content after success post
            content = ""
            tags = []
            
            navigator.path.append(hole) // navigate to hole page
            
            Task { // reload favorites since new post will automatically be favorited
                try await appModel.loadFavoriteIds()
            }
        } content: {
            Section {
                Picker(selection: $divisionId,
                       label: Label("Select Division", systemImage: "rectangle.3.group")) {
                    ForEach(appModel.divisions) { division in
                        Text(division.name)
                            .tag(division.id)
                    }
                }
            }
            
            THTagEditor($tags, maxSize: 5)
            Button {
                suggestTags()
            } label: {
                Label("Suggest Tags", systemImage: "wand.and.rays")
            }
            
            THContentEditor(content: $content)
        }
        .completed(!tags.isEmpty && !content.isEmpty)
        .warnDiscard()
        // FIXME: This modifier may cause hang during the first focus of tag editor, the reason is unknown
        .scrollDismissesKeyboard(.immediately)
    }
}
