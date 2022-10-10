import SwiftUI


/// Main page section, displaying hole contents and division switch bar
struct BrowsePage: View {
    enum SortOptions {
        case byReplyTime
        case byCreateTime
    }
    @ObservedObject var dataModel = TreeholeDataModel.shared
    @ObservedObject var preference = Preference.shared
    let divisions = TreeholeDataModel.shared.divisions
    @State var currentDivision: THDivision
    @State var holes: [THHole]
    @State var sortOption = SortOptions.byReplyTime
    @State var baseDate: Date?
    @State var endReached = false
    
    var filteredHoles: [THHole] {
        holes.filter { hole in
            // filter for blocked tags
            for tagName in hole.tags.map({ $0.name }) {
                if !preference.blockedTags.filter({ $0 == tagName }).isEmpty {
                    return false
                }
            }
            
            // filter for NSFW tags
            return !(preference.nsfwSetting == .hide && hole.nsfw)
        }
    }
    
    @State var showDatePicker = false
    @State var showEditPage = false
    @State var showTagPage = false
    @State var showFavoritesPage = false
    @State var showReportPage = false
    
    @State var loading = false
    /// uniquely identify a consistent flow of holes, should change when `holes` are cleared and a new flow is loading
    @State var loadingId = UUID()
    @State var errorInfo = ""
    
    init(holes: [THHole] = []) {
        self._currentDivision = State(initialValue: TreeholeDataModel.shared.divisions.first!)
        self._holes = State(initialValue: holes)
    }
    
    func loadMoreHoles() async {
        do {
            let currentLoadingId = loadingId
            loading = true
            defer { loading = false }
            
            var startTime: String? = nil
            if !holes.isEmpty {
                startTime = holes.last?.updateTime.ISO8601Format() // TODO: apply sort options
            } else if let baseDate = baseDate {
                startTime = baseDate.ISO8601Format()
            }
            
            let newHoles = try await DXNetworks.shared.loadHoles(startTime: startTime, divisionId: currentDivision.id)
            endReached = newHoles.isEmpty
            if currentLoadingId == loadingId { // prevent holes from older flow being inserted into new one, causing bug
                let currentIds = holes.map(\.id)
                holes.append(contentsOf: newHoles.filter { !currentIds.contains($0.id) }) // filter duplicate holes
            }
        } catch {
            errorInfo = error.localizedDescription
        }
    }
    
    var body: some View {
        List {
            // MARK: pinned section
            Section {
                ForEach(currentDivision.pinned) { hole in
                    HoleView(hole: hole)
                }
            } header: {
                VStack(alignment: .leading) {
                    switchBar
                    if !currentDivision.pinned.isEmpty {
                        Label("Pinned", systemImage: "pin.fill")
                    }
                }
            }
            
            // MARK: main section
            Section {
                ForEach(filteredHoles) { hole in
                    HoleView(hole: hole, fold: (hole.nsfw && preference.nsfwSetting == .fold))
                        .task {
                            if hole == filteredHoles.last {
                                await loadMoreHoles()
                            }
                        }
                }
            } header: {
                HStack {
                    Label("Main Section", systemImage: "text.bubble.fill")
                    Spacer()
                    if let baseDate = baseDate {
                        Text(baseDate.formatted(date: .abbreviated, time: .omitted))
                    }
                }
            } footer: {
                if !endReached {
                    LoadingFooter(loading: $loading,
                                    errorDescription: errorInfo,
                                    action: loadMoreHoles)
                }
            }
        }
        .task {
            await loadMoreHoles()
        }
        .listStyle(.grouped)
        .refreshable {
            loadingId = UUID()
            endReached = false
            holes = []
            await loadMoreHoles()
        }
        .navigationTitle(currentDivision.name)
        .sheet(isPresented: $showDatePicker) {
            datePicker
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                menu
                
                Button(action: { showEditPage = true }) {
                    Image(systemName: "square.and.pencil")
                }
                .sheet(isPresented: $showEditPage) {
                    EditForm(divisionId: currentDivision.id)
                }
            }
        }
    }
    
    private var switchBar: some View {
        Picker("division_selector", selection: $currentDivision) {
            ForEach(divisions) { division in
                Text(division.name)
                    .tag(division)
            }
        }
        .pickerStyle(.segmented)
        .offset(x: 0, y: -20)
        .onChange(of: currentDivision) { newValue in
            Task {
                loadingId = UUID()
                endReached = false
                holes = []
                await loadMoreHoles()
            }
        }
    }
    
    
    private var datePicker: some View {
        NavigationView {
            Form {
                DatePicker("Start Date",
                           selection: Binding<Date>(
                            get: { self.baseDate ?? Date() },
                            set: { self.baseDate = $0 }
                           ),
                           in: ...Date.now,
                           displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .onChange(of: baseDate) { newValue in
                    loadingId = UUID()
                    showDatePicker = false
                    holes = []
                    Task {
                        await loadMoreHoles()
                    }
                }
                
                if baseDate != nil {
                    Button("Clear Date", role: .destructive) {
                        showDatePicker = false
                        baseDate = nil
                        holes = []
                        Task {
                            await loadMoreHoles()
                        }
                    }
                }
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var menu: some View {
        Menu {
            Button {
                showFavoritesPage = true
            } label: {
                Label("Favorites", systemImage: "star")
            }
            
            Button {
                showTagPage = true
            } label: {
                Label("Tags", systemImage: "tag")
            }
            
            Button {
                showDatePicker = true
            } label: {
                Label("Select Date", systemImage: "clock.arrow.circlepath")
            }
            
            Picker("Sort Options", selection: $sortOption) {
                Text("Last Updated")
                    .tag(SortOptions.byReplyTime)
                
                Text("Last Created")
                    .tag(SortOptions.byCreateTime)
            }
            
            if TreeholeDataModel.shared.isAdmin {
                Divider()
                
                Button {
                    showReportPage = true
                } label: {
                    Label("Reports Management", systemImage: "exclamationmark.triangle")
                }
            }
            
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .background(
            Group {
                NavigationLink(destination: TagsPage(), isActive: $showTagPage) {
                    EmptyView()
                }
                NavigationLink(destination: FavoritesPage(), isActive: $showFavoritesPage) {
                    EmptyView()
                }
                NavigationLink(destination: ReportPage(), isActive: $showReportPage) {
                    EmptyView()
                }
            }
        )
    }
}
