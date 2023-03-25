import SwiftUI

struct THHoleEditSheet: View {
    @EnvironmentObject var model: THHoleModel
    @State var info: THHoleInfo
    @State var tags: [String]
    
    init(_ hole: THHole) {
        self._tags = State(initialValue: hole.tags.map(\.name))
        self._info = State(initialValue: THHoleInfo(hole))
    }
    
    var body: some View {
        FormPrimitive(title: "Edit Post Info",
                      allowSubmit: !tags.isEmpty,
                      errorTitle: "Edit Post Info Failed") {
            Section {
                Picker(selection: $info.divisionId, label: Label("Select Division", systemImage: "rectangle.3.group")) {
                    ForEach(DXModel.shared.divisions) { division in
                        Text(division.name)
                            .tag(division.id)
                    }
                }
            }
            
            THTagField(tags: $tags, max: 5)
            
            Section {
                Toggle(isOn: $info.unhidden) {
                    Label("Set Visibility", systemImage: "eye")
                }
                
                Toggle(isOn: $info.locked) {
                    Label("Lock Post", systemImage: "lock.fill")
                }
            }
        } action: {
            info.setTags(tags)
            try await model.modifyHole(info)
        }
    }
}
