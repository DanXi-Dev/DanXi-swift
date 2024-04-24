import SwiftUI
import ViewUtils
import DanXiKit

struct ModeratePage: View {
    @Environment(\.editMode) private var editMode
    @StateObject private var model = ModerateModel()
    @State private var filter = FilterOption.open
    
    private enum FilterOption {
        case open, closed
    }
    
    var body: some View {
        List(selection: $model.selectedItems) {
            Section {
                Picker(selection: $filter, label: Text("Picker")) {
                    Text("Sensitive.Open").tag(FilterOption.open)
                    Text("Sensitive.Closed").tag(FilterOption.closed)
                }
                .pickerStyle(.segmented)
                .listRowSeparator(.hidden)
            }
            
            Section {
                if filter == .closed {
                    AsyncCollection { items in
                        try await ForumAPI.listSensitive(startTime: items.last?.timeCreated ?? Date.now, open: false)
                    } content: { item in
                        SensitiveContentView(item: item)
                    }
                } else {
                    AsyncCollection(model.items,
                                    endReached: model.endReached,
                                    action: model.loadMore) { item in
                        SensitiveContentView(item: item)
                            .tag(item)
                    }
                }
            }
            .environmentObject(model)
        }
        .listStyle(.inset)
        .navigationTitle("Moderate")
        .navigationBarTitleDisplayMode(.inline)
        .watermark()
    }
}


private struct SensitiveContentView: View {
    @EnvironmentObject var model: ModerateModel
    let item: Sensitive
    
    var body: some View {
        DetailLink(value: HoleLoader(floorId: item.id)) {
            HStack(alignment: .center) {
                if let sensitive = item.sensitive {
                    if sensitive {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                VStack(alignment: .leading) {
                    Text(item.content)
                    HStack {
                        Text("##\(String(item.id))")
                        Spacer()
                        Text(item.timeCreated.formatted())
                    }
                    .foregroundStyle(.secondary)
                    .font(.caption)
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Sensitive", role: .destructive) {
                Task {
                    try await withHaptics {
                        do {
                            try await ForumAPI.setFloorSensitive(floorId: item.id, sensitive: true)
                            model.items.removeAll(where: { $0.id == item.id })
                        } catch {
                            model.objectWillChange.send() // Cause item to reappear
                            throw error
                        }
                    }
                }
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button("Normal", role: .destructive) {
                Task {
                    try await withHaptics {
                        do {
                            try await ForumAPI.setFloorSensitive(floorId: item.id, sensitive: false)
                            model.items.removeAll(where: { $0.id == item.id })
                        } catch {
                            model.objectWillChange.send() // Cause item to reappear
                            throw error
                        }
                    }
                }
            }
            .tint(.green)
        }
    }
}

@MainActor
private class ModerateModel: ObservableObject {
    @Published var items: [Sensitive] = []
    @Published var selectedItems: Set<Sensitive> = []
    @Published var endReached = false
    
    func loadMore() async throws {
        let newItems = try await ForumAPI.listSensitive(startTime: items.last?.timeCreated ?? Date.now)
        let currentIds = items.map(\.id)
        let inserteditems = newItems.filter { !currentIds.contains($0.id) }
        items += inserteditems
        endReached = inserteditems.isEmpty
    }
}
