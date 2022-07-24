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
                        THNewPost()
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
    static var previews: some View {
        Group {
            TreeHolePage()
            TreeHolePage()
                .preferredColorScheme(.dark)
        }
    }
}
