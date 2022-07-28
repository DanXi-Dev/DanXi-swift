import SwiftUI

struct TreeholePage: View {
    @ObservedObject var model = treeholeDataModel
    @State var currentDivision = THDivision.dummy
    @State var currentDivisionId = 1
    @State var holes: [THHole] = []
    
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
            .refreshable {
                await refresh()
            }
            .listStyle(.grouped)
            .navigationTitle(currentDivision.name)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    toolBar
                }
            }
        }
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
            Button(action: { showEditPage = true }) {
                Image(systemName: "square.and.pencil")
            }
            .sheet(isPresented: $showEditPage) {
                EditPage(divisionId: currentDivisionId, showNewPostPage: $showEditPage)
            }
            
            Button(action: {}) {
                Image(systemName: "ellipsis.circle")
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

struct TreeholePage_Previews: PreviewProvider {
    static var previews: some View {
        TreeholePage()
    }
}
