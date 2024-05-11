import SwiftUI
import ViewUtils
import DanXiKit

struct ModeratePage: View {
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
                        try await ForumAPI.listSensitive(startTime: items.last?.timeUpdated ?? Date.now, open: false)
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
    let content: AttributedString
    let detail: String?
    
    init(item: Sensitive) {
        var content = AttributedString(item.content)
        var detail: String? = nil
        // match sensitive detail in content, and highlight it
        if let sensitiveDetail = item.sensitiveDetail {
            let details = sensitiveDetail.split(separator: "\n")
            for part in details {
                if let range = content.range(of: part) {
                    content[range].backgroundColor = .yellow.opacity(0.3)
                } else {
                    detail = (detail ?? "") + sensitiveDetail
                }
            }
        }
        
        self.item = item
        self.content = content
        self.detail = detail
    }
    
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
                    if let detail {
                        Text(detail)
                            .bold()
                            .foregroundStyle(.red)
                    }
                    Text(content)
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
        let newItems = try await ForumAPI.listSensitive(startTime: items.last?.timeUpdated ?? Date.now)
        let currentIds = items.map(\.id)
        let inserteditems = newItems.filter { !currentIds.contains($0.id) }
        items += inserteditems
        endReached = inserteditems.isEmpty
    }
}
