import SwiftUI
import ViewUtils
import DanXiKit

struct HoleEditSheet: View {
    @ObservedObject private var divisionStore = DivisionStore.shared
    @EnvironmentObject private var model: HoleModel
    
    private let hole: Hole
    @State private var divisionId: Int
    @State private var tags: [String]
    @State private var lock: Bool
    @State private var hidden: Bool
    
    init(hole: Hole) {
        self.hole = hole
        self._divisionId = State(initialValue: hole.divisionId)
        self._tags = State(initialValue: hole.tags.map(\.name))
        self._lock = State(initialValue: hole.locked)
        self._hidden = State(initialValue: hole.hidden)
    }
    
    var body: some View {
        Sheet(String(localized: "Edit Post Info", bundle: .module)) {
            let hole = try await ForumAPI.modifyHole(id: hole.id, divisionId: divisionId, lock: lock, tags: tags, hidden: hidden)
            await MainActor.run {
                model.hole = hole
            }
        } content: {
            Section {
                Picker(selection: $divisionId, label: Label(String(localized: "Select Division", bundle: .module), systemImage: "rectangle.3.group")) {
                    ForEach(divisionStore.divisions) { division in
                        Text(division.name)
                            .tag(division.id)
                    }
                }
            }
            
            TagEditor($tags, maxSize: 5)
            
            Section {
                Toggle(isOn: $hidden) {
                    Label(String(localized: "Set Hidden", bundle: .module), systemImage: "eye")
                }
                
                Toggle(isOn: $lock) {
                    Label(String(localized: "Lock Post", bundle: .module), systemImage: "lock.fill")
                }
            }
        }
        .completed(!tags.isEmpty)
        .warnDiscard(!tags.isEmpty)
        .watermark()
    }
}
