import SwiftUI

struct TreeHolePage: View {
    @EnvironmentObject var dataModel: THDataModel
    @State var showNewPostPage = false
    @State var holes: [THHole] = []
    @State var endReached = false
    
    func changeDivision(newDivision: THDivision) async {
        guard let token = dataModel.token else {
            return
        }
        holes = []
        dataModel.currentDivision = newDivision
        endReached = false
        
        do {
            let fetchedHoles = try await THloadHoles(token: token, divisionId: newDivision.id)
            holes = fetchedHoles
        } catch {
            print("DANXI-DEBUG: change division load failed")
        }
    }
    
    func fetchMoreHoles() async {
        guard let token = dataModel.token else {
            return
        }
        
        do {
            let newHoles = try await
            THloadHoles(token: token,
                        startTime: holes.last?.iso8601UpdateTime,
                        divisionId: dataModel.currentDivision.id)
            endReached = newHoles.isEmpty
            holes.append(contentsOf: newHoles)
        } catch {
            print("DANXI-DEBUG: load new holes failed")
        }
    }
    
    func refresh() async {
        guard let token = dataModel.token else {
            return
        }
        
        if dataModel.divisions.isEmpty {
            return
        }
        
        do {
            async let fetchedDivisions = try await THloadDivisions(token: token)
            async let fetchedHoles = try await THloadHoles(token: token, divisionId: dataModel.currentDivision.id)
            
            dataModel.divisions = try await fetchedDivisions
            holes = try await fetchedHoles
        } catch {
            print("DANXI-DEBUG: refresh failed")
        }
    }
    
    var body: some View {
#if os(watchOS)
        List {
            listContent
        }
        .navigationTitle(dataModel.currentDivision.name)
#else
        List() {
            Section {
                ForEach(dataModel.currentDivision.pinned) { hole in
                    THHoleView(hole: hole)
                        .background(NavigationLink("", destination: THThread(hole: hole)).opacity(0))
                        .contextMenu {
                            holeMenu
                        }
                }
            } header: {
                VStack(alignment: .leading, spacing: 1.5) {
                    divisionSelector
                    if !dataModel.currentDivision.pinned.isEmpty {
                        Label("pinned", systemImage: "pin.fill")
                    }
                }
            }
            
            Section {
                ForEach(holes) { hole in
                    THHoleView(hole: hole)
                        .background(NavigationLink("", destination: THThread(hole: hole)).opacity(0))
                        .contextMenu {
                            holeMenu
                        }
                        .task {
                            if hole == holes.last {
                                await fetchMoreHoles()
                            }
                        }
                }
            } header: {
                if !dataModel.currentDivision.pinned.isEmpty {
                    Label("main_section", systemImage: "text.bubble.fill")
                }
            } footer: {
                if !endReached {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            }
        }
        .refreshable {
            await refresh()
        }
        .listStyle(.grouped)
        .navigationTitle(dataModel.currentDivision.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {}, label: {
                    Image(systemName: "bell")
                })
                .font(.subheadline)
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Group {
                    Button(action: { showNewPostPage = true }, label: {
                        Image(systemName: "square.and.pencil")
                    })
                    .sheet(isPresented: $showNewPostPage) {
                        THNewPost(showNewPostPage: $showNewPostPage)
                    }
                    
                    Menu(content: {
                        Button(action: {}, label: {
                            Text("option1")
                        })
                        Button(action: {}, label: {
                            Text("option2")
                        })
                    }, label: {
                        Image(systemName: "ellipsis.circle")
                    })
                }
                .font(.subheadline)
            }
        }
        
#endif
    }
    
    @ViewBuilder
    private var listContent: some View {
        if !dataModel.divisions.isEmpty {
            divisionSelector
        }
        
        ForEach(dataModel.currentDivision.pinned) { hole in
            NavigationLink(destination: THThread(hole: hole)) {
                THHoleView(hole: hole)
            }
        }
        
        ForEach(holes) { hole in
            NavigationLink(destination: THThread(hole: hole)) {
                THHoleView(hole: hole)
            }
        }
    }
    
    private var divisionSelector: some View {
        Picker("divisions", selection: $dataModel.currentDivision) {
            ForEach(dataModel.divisions, id: \.self) {division in
                Text(division.name)
            }
        }
#if !os(watchOS)
        .pickerStyle(.segmented)
#endif
        .padding()
        // change division
        .onChange(of: dataModel.currentDivision) { newValue in
            Task {
                await changeDivision(newDivision: newValue)
            }
        }
        .task {
            await fetchMoreHoles()
        }
    }
    
    private var holeMenu: some View {
        Group {
            Button {
                // TODO: bookmark
            } label: {
                Label("add_bookmark", systemImage: "bookmark")
            }
            
            Button {
                // TODO: copy hole id
            } label: {
                Label("copy_hole_id", systemImage: "square.and.arrow.up")
            }
        }
    }
}

struct TreeHolePage_Previews: PreviewProvider {
    static let tag = THTag(id: 1, temperature: 1, name: "Tag")
    
    static let floor = THFloor(
        id: 1234567, holeId: 123456,
        iso8601UpdateTime: "2022-04-14T08:23:12.761042+08:00",
        iso8601CreateTime: "2022-04-14T08:23:12.761042+08:00",
        updateTime: Date.now, createTime: Date.now,
        like: 12,
        liked: true,
        storey: 5,
        content: """
        Hello, **Dear** readers!
        
        We can make text *italic*, ***bold italic***, or ~~striked through~~.
        
        You can even create [links](https://www.twitter.com/twannl) that actually work.
        
        Or use `Monospace` to mimic `Text("inline code")`.
        
        """,
        posterName: "Dax")
    
    static let hole = THHole(
        id: 123456,
        divisionId: 1,
        view: 15,
        reply: 13,
        iso8601UpdateTime: "2022-04-14T08:23:12.761042+08:00",
        iso8601CreateTime: "2022-04-14T08:23:12.761042+08:00",
        updateTime: Date.now, createTime: Date.now,
        tags: Array(repeating: tag, count: 5),
        firstFloor: floor, lastFloor: floor, floors: Array(repeating: floor, count: 10))
    
    static let division = THDivision(id: 1, name: "树洞", description: "", pinned: Array(repeating: hole, count: 2))
    
    static let dataModel = THDataModel(divisions: Array(repeating: division, count: 4), tags: [])
    
    static var previews: some View {
        Group {
            TreeHolePage()
            TreeHolePage()
                .preferredColorScheme(.dark)
        }
        .environmentObject(dataModel)
    }
}
