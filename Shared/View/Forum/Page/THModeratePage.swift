import SwiftUI
import ViewUtils

struct THModeratePage: View {
    @Environment(\.editMode) private var editMode
    @StateObject private var model = THModerateModel()
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
                        return try await THRequests.listSensitive(startTime: items.last?.createTime.ISO8601Format(), open: false)
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


fileprivate struct SensitiveContentView: View {
    @EnvironmentObject var model: THModerateModel
    let item: THSensitiveEntry
    
    var body: some View {
        DetailLink(value: THHoleLoader(floorId: item.id)) {
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
                        Text(item.createTime.formatted())
                    }
                    .foregroundStyle(.secondary)
                    .font(.caption)
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Sensitive", role: .destructive) {
                Task {
                    prepareHaptic()
                    do {
                        try await THRequests.setSensitive(id: item.id, sensitive: true)
                        haptic(.success)
                        model.items.removeAll(where: { $0.id == item.id })
                    } catch {
                        haptic(.error)
                        model.objectWillChange.send() // Cause item to reappear
                    }
                }
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button("Normal", role: .destructive) {
                Task {
                    prepareHaptic()
                    do {
                        try await THRequests.setSensitive(id: item.id, sensitive: false)
                        haptic(.success)
                        model.items.removeAll(where: { $0.id == item.id })
                    } catch {
                        haptic(.error)
                        model.objectWillChange.send() // Cause item to reappear
                    }
                }
            }
            .tint(.green)
        }
    }
}


@MainActor
class THModerateModel: ObservableObject {
    @Published var items: [THSensitiveEntry] = []
    @Published var selectedItems: Set<THSensitiveEntry> = []
    @Published var endReached = false
    
    func loadMore() async throws {
        let newItems = try await THRequests.listSensitive(startTime: items.last?.createTime.ISO8601Format())
        let currentIds = items.map(\.id)
        let inserteditems = newItems.filter { !currentIds.contains($0.id) }
        items += inserteditems
        endReached = inserteditems.isEmpty
    }
}

#Preview {
    NavigationStack {
        THModeratePage()
    }
}
