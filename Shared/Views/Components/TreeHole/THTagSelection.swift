import SwiftUI

struct THTagSelection: View {
    @EnvironmentObject var dataModel: THDataModel
    
    @Binding var tagList: [THTag]
    @State var searchText = ""
    
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
            return dataModel.tags
        } else {
            // TODO: filter tags that already exists
            return dataModel.tags.filter { $0.name.contains(searchText) }
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
