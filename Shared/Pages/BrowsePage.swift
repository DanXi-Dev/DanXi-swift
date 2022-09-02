import SwiftUI


/// Main page section, displaying hole contents and division switch bar
struct BrowsePage: View {
    enum SortOptions {
        case byReplyTime
        case byCreateTime
    }
    
    let divisions: [THDivision]
    @State var currentDivision: THDivision
    @State var holes: [THHole]
    @State var sortOption = SortOptions.byReplyTime
    
    @State var showEditPage = false
    @State var showTagPage = false
    @State var showFavoritesPage = false
    
    @State var loading = false
    @State var errorInfo = ErrorInfo()
    
    init(divisions: [THDivision], holes: [THHole] = []) {
        self.divisions = divisions
        self._currentDivision = State(initialValue: divisions.first!)
        self._holes = State(initialValue: holes)
    }
    
    func loadMoreHoles() async {
        do {
            loading = true
            defer { loading = false }
            
            let divisionId = currentDivision.id
            let startTime = holes.last?.updateTime.ISO8601Format() // TODO: apply sort options
            let newHoles = try await NetworkRequests.shared.loadHoles(startTime: startTime, divisionId: currentDivision.id)
            if divisionId == currentDivision.id { // user may change division during network request
                holes.append(contentsOf: newHoles)
            }
        } catch NetworkError.ignore {
            // cancelled, ignore
        } catch let error as NetworkError {
            errorInfo = error.localizedErrorDescription
        } catch {
            errorInfo = ErrorInfo(title: "Unknown Error",
                                  description: "Error description: \(error.localizedDescription)")
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
                ForEach(holes) { hole in
                    HoleView(hole: hole)
                        .task {
                            if hole == holes.last {
                                await loadMoreHoles()
                            }
                        }
                }
            } header: {
                Label("Main Section", systemImage: "text.bubble.fill")
            } footer: {
                ListLoadingView(loading: $loading,
                                errorDescription: errorInfo.description,
                                action: loadMoreHoles)
            }
        }
        .task {
            await loadMoreHoles()
        }
        .listStyle(.grouped)
        .refreshable {
            holes = []
            await loadMoreHoles()
        }
        .navigationTitle(currentDivision.name)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                menu
                
                Button(action: { showEditPage = true }) {
                    Image(systemName: "square.and.pencil")
                }
                .sheet(isPresented: $showEditPage) {
                    EditPage(divisionId: currentDivision.id)
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
        .offset(x: 0, y: -40)
        .onChange(of: currentDivision) { newValue in
            Task {
                holes = []
                await loadMoreHoles()
            }
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
            
            Picker("Sort Options", selection: $sortOption) {
                Text("Last Updated")
                    .tag(SortOptions.byReplyTime)
                
                Text("Last Created")
                    .tag(SortOptions.byCreateTime)
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
            }
        )
    }
}
