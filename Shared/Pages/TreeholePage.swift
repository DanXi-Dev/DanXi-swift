import SwiftUI
import Foundation

extension String {
    /// If lhs content matches rhs regex, returns true
    static func ~= (lhs: String, rhs: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: rhs) else { return false }
        let range = NSRange(location: 0, length: lhs.utf16.count)
        return regex.firstMatch(in: lhs, options: [], range: range) != nil
    }
    
    /// Convert Treehole-formatted content to plain text, stripping URLs, markdown and latex
    func stripTreeholeSyntax() -> String {
        // TODO: This currently only removes markdown syntax
        guard let attributedString = try? NSAttributedString(markdown: self) else {
            return "DEBUG: Failed to convert content to Attributed String"
        }
        return attributedString.string
    }
}

struct TreeholePage: View {
    @ObservedObject var model = treeholeDataModel
    @State var currentDivision = THDivision.dummy
    @State var currentDivisionId = 1
    @State var holes: [THHole] = []
    
    @State var searchText = ""
    
    @State var showEditPage = false
    
    func initialLoad() async {
        do {
            let divisions = try await networks.loadDivisions()
            currentDivision = divisions[0]
            model.divisions = divisions
            Task {
                await loadMoreHoles()
            }
        } catch {
            print("DANXI-DEBUG: load division failed")
        }
    }
    
    func loadMoreHoles() async {
        do {
            let newHoles = try await networks.loadHoles(startTime: holes.last?.iso8601UpdateTime, divisionId: currentDivision.id)
            holes.append(contentsOf: newHoles)
        } catch {
            print("DANXI-DEBUG: load holes failed")
        }
    }
    
    func changeDivision(division: THDivision) async {
        holes = []
        currentDivision = division
        await loadMoreHoles()
    }
    
    func refresh() async {
        holes = []
        await loadMoreHoles()
    }
    
    var body: some View {
        if model.divisions.isEmpty {
            ProgressView()
                .task {
                    await initialLoad()
                }
        } else {
            List {
                if searchText.isEmpty {
                    pinnedSection
                    mainSection
                } else {
                    searchSection
                }
            }
            .refreshable {
                await refresh()
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
            .listStyle(.grouped)
            .navigationTitle(currentDivision.name)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    toolBar
                }
            }
        }
    }
    
    private var filteredTags: [THTag] {
        return model.tags.filter { $0.name.contains(searchText) }
    }
    
    private var searchSection: some View {
        Section {
            NavigationLink(destination: SearchTextPage(keyword: searchText)) {
                Label(searchText, systemImage: "magnifyingglass")
            }
            
            // navigate to hole by ID, assuming hole ID length is between 3 and 8
            if searchText ~= "^#[0-9]{3,8}$", let holeId = Int(searchText.dropFirst(1)) {
                NavigationLink(destination: PostPage(holeId: holeId)) {
                    Label(searchText, systemImage: "number")
                }
            }
            
            // navigate to floor by ID, assuming hole ID length is between 4 and 9
            if searchText ~= "^##[0-9]{4,9}$", let floorId = Int(searchText.dropFirst(2)) {
                NavigationLink(destination: PostPage(targetFloorId: floorId)) {
                    Label(searchText, systemImage: "number")
                }
            }
            
            ForEach(filteredTags) { tag in
                NavigationLink(destination: SearchTagPage(tagname: tag.name, divisionId: currentDivisionId)) {
                    Label(tag.name, systemImage: "tag")
                }
            }
            
        } header: {
            switchBar
        }
    }
    
    private var pinnedSection: some View {
        Section {
            ForEach(currentDivision.pinned) { hole in
                HoleView(hole: hole)
                    .background(NavigationLink("", destination: PostPage(hole: hole)).opacity(0))
            }
        } header: {
            VStack(alignment: .leading) {
                switchBar
                if !currentDivision.pinned.isEmpty {
                    Label("pinned", systemImage: "pin.fill")
                }
            }
        }
        .textCase(nil)
    }
    
    private var mainSection: some View {
        Section {
            ForEach(holes) { hole in
                HoleView(hole: hole)
                    .background(NavigationLink("", destination: PostPage(hole: hole)).opacity(0))
                    .task {
                        if hole == holes.last {
                            await loadMoreHoles()
                        }
                    }
            }
        } header: {
            Label("main_section", systemImage: "text.bubble.fill")
        } footer: {
            spinner
        }
        .textCase(nil)
    }
    
    private var switchBar: some View {
        Picker("division_selector", selection: $currentDivisionId) {
            ForEach(model.divisions) { division in
                Text(division.name)
                    .tag(division.id)
            }
        }
        .pickerStyle(.segmented)
        .offset(x: 0, y: -40)
        .onChange(of: currentDivisionId) { newValue in
            Task {
                let newDivision = model.divisions[newValue - 1]
                await changeDivision(division: newDivision)
            }
        }
    }
    
    private var toolBar: some View {
        Group {
            ToolbarMenu() // menu item can't perform navigation, this is a workaround
            
            Button(action: { showEditPage = true }) {
                Image(systemName: "square.and.pencil")
            }
            .sheet(isPresented: $showEditPage) {
                EditPage(divisionId: currentDivisionId, showNewPostPage: $showEditPage)
            }
        }
    }
    
    private var spinner: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }
}

struct ToolbarMenu: View {
    @State private var isActive = false // menu navigation workaround
    
    var body: some View {
        Menu {
            Button {
                self.isActive = true
            } label: {
                Label("favorites", systemImage: "star")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .background(
            NavigationLink(destination: FavoritesPage(), isActive: $isActive) {
                EmptyView()
            })
    }
    
}

struct TreeholePage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TreeholePage()
        }
    }
}
