import SwiftUI
import ViewUtils
import DanXiKit

struct MyPostPage: View {
    @ObservedObject private var settings = ForumSettings.shared
    
    var body: some View {
        ForumList {
            AsyncCollection { (presentations: [HolePresentation]) in
                let holes = try await ForumAPI.listMyHoles(startTime: presentations.last?.hole.timeUpdated)
                return holes.map { HolePresentation(hole: $0) }
            } content: { presentation in
                if !settings.hiddenMyHoles.contains(presentation.hole.id) {
                    Section {
                        HoleView(presentation: presentation)
                            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            withAnimation {
                                settings.hiddenMyHoles.append(presentation.hole.id)
                            }
                        } label: {
                            Label {
                                Text("Hide", bundle: .module)
                            } icon: {
                                Image(systemName: "eye.slash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "My Post", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .watermark()
    }
}
