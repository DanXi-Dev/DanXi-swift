import SwiftUI

struct THHoleEditSheet: View {
    @ObservedObject private var appModel = THModel.shared
    @EnvironmentObject private var model: THHoleModel
    @State private var info: THHoleInfo
    @State private var tags: [String]
    
    init(_ hole: THHole) {
        self._tags = State(initialValue: hole.tags.map(\.name))
        self._info = State(initialValue: THHoleInfo(hole))
    }
    
    var body: some View {
        Sheet("Edit Post Info") {
            info.setTags(tags)
            try await model.modifyHole(info)
        } content: {
            Section {
                Picker(selection: $info.divisionId, label: Label("Select Division", systemImage: "rectangle.3.group")) {
                    ForEach(appModel.divisions) { division in
                        Text(division.name)
                            .tag(division.id)
                    }
                }
            }
            
            THTagEditor($tags, maxSize: 5)
            
            Section {
                Toggle(isOn: $info.unhidden) {
                    Label("Set Visibility", systemImage: "eye")
                }
                
                Toggle(isOn: $info.lock) {
                    Label("Lock Post", systemImage: "lock.fill")
                }
            }
        }
        .completed(!tags.isEmpty)
        .warnDiscard(!tags.isEmpty)
    }
}
