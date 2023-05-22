import SwiftUI

struct THTagsPage: View {
    @State private var query = ""
    
    var body: some View {
        THBackgroundList {
            let tags = DXModel.shared.tags.filter { tag in
                if query.isEmpty {
                    return tag.temperature >= 10 
                }
                
                return tag.name.contains(query)
            }
            
            ForEach(tags) { tag in
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
        .searchable(text: $query, prompt: Text("Search in Tags"))
    }
}
