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
        List {
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
                    AsyncCollection(model.closedItems, endReached: model.closedEndReached, action: model.loadMoreClosed) { item in
                        SensitiveContentView(item: item)
                    }
                } else {
                    AsyncCollection(model.openItems, endReached: model.openEndReached, action: model.loadMoreOpen) { item in
                        SensitiveContentView(item: item)
                            .tag(item)
                    }
                }
            }
            .environmentObject(model)
        }
        .listStyle(.inset)
        .toolbar {
            Menu {
                Picker(selection: $model.sortOption) {
                    Text("Last Updated")
                        .tag(ModerateModel.SortOption.replyTime)
                    Text("Last Created")
                        .tag(ModerateModel.SortOption.createTime)
                } label: {
                    Label("Sort By", systemImage: "arrow.up.arrow.down")
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
            
        }
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
                            model.openItems.removeAll(where: { $0.id == item.id })
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
                            model.openItems.removeAll(where: { $0.id == item.id })
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
class ModerateModel: ObservableObject {
    @Published var sortOption: SortOption = .createTime {
        didSet {
            closedItems = []
            openItems = []
        }
    }
    @Published var closedItems: [Sensitive] = []
    @Published var closedEndReached = false
    @Published var openItems: [Sensitive] = []
    @Published var openEndReached = false
    
    enum SortOption {
        case replyTime
        case createTime
    }
    
    func loadMoreClosed() async throws {
        let startTime = if let last = closedItems.last {
            switch sortOption {
            case .replyTime:
                last.timeUpdated
            case .createTime:
                last.timeCreated
            }
        } else {
            Date.now
        }
        let order = switch sortOption {
        case .replyTime:
            "time_updated"
        case .createTime:
            "time_created"
        }
        let newItems = try await ForumAPI.listSensitive(startTime: startTime, open: false, order: order)
        let currentIds = closedItems.map(\.id)
        let inserteditems = newItems.filter { !currentIds.contains($0.id) }
        closedEndReached = inserteditems.isEmpty
        closedItems += inserteditems
    }
    
    func loadMoreOpen() async throws {
        let startTime = if let last = openItems.last {
            switch sortOption {
            case .replyTime:
                last.timeUpdated
            case .createTime:
                last.timeCreated
            }
        } else {
            Date.now
        }
        let order = switch sortOption {
        case .replyTime:
            "time_updated"
        case .createTime:
            "time_created"
        }
        let newItems = try await ForumAPI.listSensitive(startTime: startTime, open: true, order: order)
        let currentIds = openItems.map(\.id)
        let inserteditems = newItems.filter { !currentIds.contains($0.id) }
        openEndReached = inserteditems.isEmpty
        openItems += inserteditems
    }
}
