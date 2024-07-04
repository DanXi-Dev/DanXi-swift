import SwiftUI
import ViewUtils
import DanXiKit

struct ModeratePage: View {
    @StateObject private var model = ModerateModel()
    @State private var filter = FilterOption.open
    @State private var showDatePicker = false
    
    private enum FilterOption {
        case open, closed
    }
    
    var body: some View {
        List {
            Section {
                Picker(selection: $filter, label: Text("Picker", bundle: .module)) {
                    Text("Sensitive.Open", bundle: .module).tag(FilterOption.open)
                    Text("Sensitive.Closed", bundle: .module).tag(FilterOption.closed)
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
        .refreshable {
            model.closedItems = []
            model.openItems = []
        }
        .listStyle(.inset)
        .toolbar {
            Menu {
                Picker(selection: $model.sortOption) {
                    Text("Last Updated", bundle: .module)
                        .tag(ModerateModel.SortOption.replyTime)
                    Text("Last Created", bundle: .module)
                        .tag(ModerateModel.SortOption.createTime)
                } label: {
                    Label(String(localized: "Sort By", bundle: .module), systemImage: "arrow.up.arrow.down")
                }
                
                Button {
                    showDatePicker = true
                } label: {
                    Label(String(localized: "Select Date", bundle: .module), systemImage: "clock.arrow.circlepath")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            
        }
        .sheet(isPresented: $showDatePicker) {
            datePicker
        }
        .navigationTitle(String(localized: "Moderate", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
        .watermark()
    }
    
    private var datePicker: some View {
        NavigationStack {
            Form {
                let dateBinding = Binding<Date>(
                    get: { model.baseDate ?? Date() },
                    set: { model.baseDate = $0 }
                )
                
                DatePicker(selection: dateBinding, in: ...Date.now, displayedComponents: [.date]) {
                    Text("Start Date", bundle: .module)
                }
                    .datePickerStyle(.graphical)
                
                if model.baseDate != nil {
                    Button(role: .destructive) {
                        model.baseDate = nil
                        showDatePicker = false
                    } label: {
                        Text("Clear Date", bundle: .module)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showDatePicker = false
                    } label: {
                        Text("Done", bundle: .module)
                    }
                }
            }
        }
        .navigationTitle(String(localized: "Select Date", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }
}


private struct SensitiveContentView: View {
    enum Section {
        case text(AttributedString)
        case image(URL)
    }
    
    @EnvironmentObject var model: ModerateModel
    let item: Sensitive
    let sections: [Section]
    let detail: String?
    
    init(item: Sensitive) {
        var content = (try? AttributedString(markdown: item.content)) ?? AttributedString(item.content)
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
        
        var sections: [Section] = []
        var currentSection: AttributedString?
        for run in content.runs {
            if let imageURL = run.imageURL {
                if let currentSection {
                    sections.append(.text(currentSection))
                }
                sections.append(.image(imageURL))
            } else {
                if currentSection == nil {
                    currentSection = AttributedString(content[run.range])
                } else {
                    currentSection?.append(content[run.range])
                }
            }
        }
        if let currentSection {
            sections.append(.text(currentSection))
        }
        
        
        self.item = item
        self.sections = sections
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
                    
                    VStack(alignment: .leading) {
                        ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                            switch section {
                            case .image(let imageURL):
                                if Proxy.shared.shouldTryProxy, Proxy.shared.outsideCampus {
                                    ImageView(imageURL, proxiedURL: Proxy.shared.createProxiedURL(url: imageURL))
                                } else {
                                    ImageView(imageURL)
                                }
                            case .text(let attributedString):
                                Text(attributedString)
                            }
                        }
                    }
                    
                    HStack {
                        Text(verbatim: "##\(String(item.id))")
                        Spacer()
                        Text(item.timeCreated.formatted())
                    }
                    .foregroundStyle(.secondary)
                    .font(.caption)
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
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
            } label: {
                Text("Sensitive", bundle: .module)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(role: .destructive) {
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
            } label: {
                Text("Normal", bundle: .module)
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
    @Published var baseDate: Date? = nil {
        didSet {
            openItems = []
        }
    }
    
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
        } else if let baseDate {
            baseDate
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
