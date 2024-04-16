import SwiftUI
import ViewUtils

struct THPostSheet: View {
    @EnvironmentObject private var navigator: AppNavigator
    @ObservedObject private var appModel = THModel.shared
    @State var divisionId: Int
    @State private var content = ""
    @State private var tags: [String] = []
    @State private var runningImageUploadTask = 0
    
    var body: some View {
        Sheet("New Post") {
            let hole = try await THRequests.createHole(
                content: content,
                divisionId: divisionId,
                tags: tags)
            
            // reset stashed draft content after success post
            content = ""
            tags = []
            
            navigator.pushDetail(value: hole, replace: true) // navigate to hole page
            
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
                       .labelStyle(.titleOnly)
            }
            
            Section("Tags") {
                THTagEditor($tags, maxSize: 5)
            }
            
            THContentEditor(content: $content, runningImageUploadTasks: $runningImageUploadTask)
        }
        .completed(!tags.isEmpty && !content.isEmpty && runningImageUploadTask <= 0)
        .warnDiscard(!tags.isEmpty || !content.isEmpty || runningImageUploadTask > 0)
    }
}
