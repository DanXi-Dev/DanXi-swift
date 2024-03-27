import SwiftUI

struct THTagsPage: View {
    @ObservedObject private var appModel = THModel.shared
    @State private var query = ""
    
    private var filteredTags: [THTag] {
        appModel.tags.filter { tag in
            if query.isEmpty {
                return tag.temperature >= 10
            }
            
            return tag.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    var body: some View {
        AsyncContentView(finished: !appModel.tags.isEmpty) {
            appModel.tags = try await appModel.loadTags()
        } content: { 
            THBackgroundList {
                ForEach(filteredTags) { tag in
                    NavigationLink(value: tag) {
                        HStack {
                            Label(tag.name, systemImage: "tag")
                                .foregroundColor(randomColor(tag.name))
                            Label(String(tag.temperature), systemImage: "flame")
                                .font(.footnote)
                                .foregroundColor(.separator)
                        }
                    }
                }
            }
            .listStyle(.inset)
            .navigationTitle("All Tags")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: Text("Search in Tags"))
        }
    }
}
