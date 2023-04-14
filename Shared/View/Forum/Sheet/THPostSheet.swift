import SwiftUI

struct THPostSheet: View {
    @State var divisionId: Int
    @AppStorage("post-draft") var content = ""
    @State var tags: [String] = []
    
    var body: some View {
        Sheet("New Post") {
            try await THRequests.createHole(
                content: content,
                divisionId: divisionId,
                tags: tags)
            content = ""
            
            Task { // reload favorites since new post will automatically be favorited
                try await DXModel.shared.loadFavoriteIds()
            }
        } content: {
            Section {
                Picker(selection: $divisionId,
                       label: Label("Select Division", systemImage: "rectangle.3.group")) {
                    ForEach(DXModel.shared.divisions) { division in
                        Text(division.name)
                            .tag(division.id)
                    }
                }
            }
            
            THTagEditor($tags, maxSize: 5)
            
            Section {
                TextEditView($content,
                             placeholder: "Enter post content")
            } header: {
                Text("TH Edit Alert")
            }
            .textCase(nil)
            
            if !content.isEmpty {
                Section {
                    THFloorContent(content, interactable: false)
                } header: {
                    Text("Preview")
                }
            }
        }
        .completed(!tags.isEmpty && !content.isEmpty)
    }
}

struct THPostSheet_Previews: PreviewProvider {
    static var previews: some View {
        THPostSheet(divisionId: 1)
    }
}
