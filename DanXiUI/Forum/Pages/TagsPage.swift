import SwiftUI
import ViewUtils
import DanXiKit

struct TagsPage: View {
    @ObservedObject private var tagStore = TagStore.shared
    @State private var searchText = ""
    
    private var filteredTags: [Tag] {
        tagStore.tags.filter { tag in
            if searchText.isEmpty {
                return tag.temperature >= 10
            }
            
            return tag.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    
    var body: some View {
        ForumList {
            ForEach(filteredTags) { tag in
                ContentLink(value: tag) {
                    HStack {
                        Label(tag.name, systemImage: "tag")
                            .foregroundColor(hashColorForTreehole(tag.name))
                        Label(String(tag.temperature), systemImage: "flame")
                            .font(.footnote)
                            .foregroundColor(.separator)
                    }
                }
            }
        }
        .navigationTitle("All Tags")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: Text("Search in Tags"))
    }
}
