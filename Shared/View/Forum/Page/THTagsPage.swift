import SwiftUI

struct TagsPage: View {
    @State private var errorInfo: String? = nil
    @State private var searchText = ""
    
    private var filteredTags: [THTag] {
        if searchText.isEmpty { return THStore.shared.tags }
        return THStore.shared.tags.filter { $0.name.contains(searchText) }
    }
    
    var body: some View {
        List {
            ForEach(filteredTags) { tag in
                NavigationLink(value: tag) {
                    TagRowView(tag: tag)
                }
            }
        }
        .searchable(text: $searchText)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Tags")
    }
}

struct TagRowView: View {
    let tag: THTag
    
    var body: some View {
        HStack {
            Text(tag.name)
                .tagStyle(color: randomColor(tag.name))
            Label(String(tag.temperature), systemImage: "flame")
        }
        .foregroundColor(randomColor(tag.name))
    }
}

struct THTagPage_Previews: PreviewProvider {
    static var previews: some View {
        TagsPage()
    }
}
