import SwiftUI

struct THHoleEditSheet: View {
    @EnvironmentObject var model: THHoleModel
    @State var info: THHoleInfo
    
    init(_ info: THHoleInfo) {
        self._info = State(initialValue: info)
    }
    
    var body: some View {
        FormPrimitive(title: "Edit Post Info",
                      allowSubmit: !info.tags.isEmpty,
                      errorTitle: "Edit Post Info Failed") {
            Section {
                Picker(selection: $info.divisionId, label: Label("Select Division", systemImage: "rectangle.3.group")) {
                    ForEach(DXModel.shared.divisions) { division in
                        Text(division.name)
                            .tag(division.id)
                    }
                }
            }
            
            THTagField(tags: $info.tags, max: 5)
            
            Section {
                Toggle(isOn: $info.unhidden) {
                    Label("Set Visibility", systemImage: "eye")
                }
                
                Toggle(isOn: $info.locked) {
                    Label("Lock Post", systemImage: "lock.fill")
                }
            }
        } action: {
            try await model.modifyHole(info)
        }
    }
}
