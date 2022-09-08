import SwiftUI

struct EditInfoPage: View {
    let holeId: Int
    @State var divisionId: Int
    @State var tags: [THTag]
    
    var body: some View {
        PrimitiveForm(title: "Edit Post Info",
                      allowSubmit: !tags.isEmpty,
                      errorTitle: "Edit Post Info Failed") {
            Section {
                Picker(selection: $divisionId, label: Label("Select Division", systemImage: "rectangle.3.group")) {
                    ForEach(TreeholeDataModel.shared.divisions) { division in
                        Text(division.name)
                            .tag(division.id)
                    }
                }
            }
            
            TagField(tags: $tags, max: 5)
        } action: {
            try await NetworkRequests.shared.alterHole(holeId: holeId,
                                                       tags: tags,
                                                       divisionId: divisionId)
        }

    }
}

struct EditInfoPage_Previews: PreviewProvider {
    static var previews: some View {
        EditInfoPage(holeId: 0, divisionId: 0, tags: [])
    }
}
