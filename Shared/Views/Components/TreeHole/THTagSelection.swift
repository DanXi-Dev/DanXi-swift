import SwiftUI

struct THTagSelection: View {
    @Binding var tagList: [THTag]
    @State var searchText = ""
    
    // TODO: get real tags from server
    let serverTags = [
        THTag(id: 1, temperature: 13, name: "Tag1"),
        THTag(id: 2, temperature: 14, name: "Tag2"),
        THTag(id: 3, temperature: 11, name: "Tag3")]
    
    var body: some View {
        List {
            if tagList.isEmpty {
                Text("no_tags")
                    .foregroundColor(.primary.opacity(0.25))
            } else {
                TagList(tags: tagList)
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always)) {
            
            ForEach(searchResults) { result in
                HStack(alignment: .bottom, spacing: 15) {
                    Text(result.name)
                        .tagStyle(color: .pink, fontSize: 18)
                    Label(String(result.temperature), systemImage: "flame")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Spacer()
                    Button("add", action: { tagList.append(result) })
                }
            }
        }
        .navigationTitle("select_tags")
    }
    
    var searchResults: [THTag] {
        if searchText.isEmpty {
            return serverTags
        } else {
            // TODO: filter tags that already exists
            return serverTags.filter { $0.name.contains(searchText) }
        }
    }
}

struct THTagSelection_Previews: PreviewProvider {
    @State static var list: [THTag] = []
    
    static var previews: some View {
        NavigationView {
            THTagSelection(tagList: $list)
        }
    }
}
