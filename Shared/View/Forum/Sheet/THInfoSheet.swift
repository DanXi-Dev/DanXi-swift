import SwiftUI

struct THInfoSheet: View {
    let holeId: Int
    @State var divisionId: Int
    @State var tags: [String]
    @State var hidden: Bool
    
    var body: some View {
        FormPrimitive(title: "Edit Post Info",
                      allowSubmit: !tags.isEmpty,
                      errorTitle: "Edit Post Info Failed") {
            Section {
                Picker(selection: $divisionId, label: Label("Select Division", systemImage: "rectangle.3.group")) {
                    ForEach(TreeholeStore.shared.divisions) { division in
                        Text(division.name)
                            .tag(division.id)
                    }
                }
            }
            
            THTagField(tags: $tags, max: 5)
            
            Section {
                Toggle(isOn: $hidden) {
                    Label("Hide Hole", systemImage: "eye.slash")
                }
            }
        } action: {
            try await TreeholeRequests.modifyHole(holeId: holeId,
                                                   tags: tags,
                                                   divisionId: divisionId,
                                                   unhidden: !hidden)
        }
    }
}

struct THInfoSheet_Previews: PreviewProvider {
    static var previews: some View {
        THInfoSheet(holeId: 0, divisionId: 0, tags: [], hidden: false)
    }
}
