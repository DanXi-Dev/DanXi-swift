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
        ZStack(alignment: .bottomTrailing) {
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
            }
            .listStyle(.inset)
            .navigationTitle("Moderate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if filter == .open {
                    EditButton()
                }
            }
            .watermark()
            
            HStack(spacing: 40) {
                if !model.selectedItems.isEmpty {
                    AsyncButton {
                        await model.setSelected(sensitive: false)
                        editMode?.wrappedValue = .inactive
                    } label: {
                        Label("正常", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title2)
                            .fontWeight(.black)
                    }
                    
                    AsyncButton {
                        await model.setSelected(sensitive: true)
                        editMode?.wrappedValue = .inactive
                    } label: {
                        Label("敏感", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.title2)
                            .fontWeight(.black)
                    }
                }
            }
            .padding(.init(top: 0, leading: 0, bottom: 45, trailing: 30))
            .font(.largeTitle)
        }
    }
}


fileprivate struct SensitiveContentView: View {
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
                } else {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundStyle(.secondary)
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
    
    func removeSelected() {
        let ids = selectedItems.map(\.id)
        withAnimation {
            items = items.filter { !ids.contains($0.id) }
        }
    }
    
    func setSelected(sensitive: Bool) async {
        let ids = selectedItems.map(\.id)
        var successIds: [Int] = []
        for id in ids {
            do {
                try await THRequests.setSensitive(id: id, sensitive: sensitive)
                successIds.append(id)
            } catch {
                // print(error)
            }
        }
        
        withAnimation {
            items = items.filter { !successIds.contains($0.id) }
        }
    }
}

#Preview {
    NavigationStack {
        THModeratePage()
    }
}
