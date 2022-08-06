import SwiftUI

struct PostPage: View {
    @State var hole: THHole?
    @State var floors: [THFloor] = []
    @State var endReached = false
    @State var favorited: Bool
    @State var holeId: Int
    var targetFloorId: Int? = nil
    
    init(hole: THHole) {
        self._hole = State(initialValue: hole)
        self._favorited = State(initialValue: treeholeDataModel.user?.favorites.contains(hole.id) ?? false)
        self._holeId = State(initialValue: hole.id)
    }
    
    init(holeId: Int) { // init from hole ID, load info afterwards
        self._hole = State(initialValue: nil)
        self._favorited = State(initialValue: treeholeDataModel.user?.favorites.contains(holeId) ?? false)
        self._holeId = State(initialValue: holeId)
    }
    
    init(targetFloorId: Int) { // init from floor ID, scroll to that floor
        self.targetFloorId = targetFloorId
        self._hole = State(initialValue: nil)
        self._holeId = State(initialValue: 0)
        self._favorited = State(initialValue: false)
    }
    
    @State var showReplyPage = false
    
    func loadMoreFloors() async {
        do {
            let newFloors = try await networks.loadFloors(holeId: holeId, startFloor: floors.count)
            floors.append(contentsOf: newFloors)
            endReached = newFloors.isEmpty
        } catch {
            print("DANXI-DEBUG: load floors failed")
        }
    }
    
    func loadHoleInfo() async {
        do {
            self.hole = try await networks.loadHoleById(holeId: holeId)
        } catch {
            print("DANXI-DEBUG: load hole info failed")
        }
    }
    
    func loadToTargetFloor() async {
        guard let targetFloorId = targetFloorId else {
            return
        }
        
        do {
            let targetFloor = try await networks.loadFloorById(floorId: targetFloorId)
            
            self.holeId = targetFloor.holeId
            self.hole = try await networks.loadHoleById(holeId: holeId)
            
            var newFloors: [THFloor] = []
            var floors: [THFloor] = []
            repeat {
                newFloors = try await networks.loadFloors(holeId: holeId, startFloor: floors.count)
                floors.append(contentsOf: newFloors)
                if newFloors.contains(targetFloor) {
                    break
                }
            } while !newFloors.isEmpty
            self.floors = floors // insert to view at last, preventing automatic refresh causing URLSession to cancel
        } catch {
            print("DANXI-DEBUG: load to target floor failed")
        }
    }
    
    func toggleFavorites() async {
        do {
            let favorites = try await networks.toggleFavorites(holeId: holeId, add: !favorited)
            treeholeDataModel.updateFavorites(favorites: favorites)
            favorited = favorites.contains(holeId)
        } catch {
            print("DANXI-DEBUG: toggle favorite failed")
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                Section {
                    ForEach(floors) { floor in
                        FloorView(floor: floor, isPoster: floor.posterName == hole?.firstFloor.posterName ?? "")
                            .task {
                                if floor == floors.last {
                                    await loadMoreFloors()
                                }
                            }
                            .id(floor.id)
                    }
                } header: {
                    if let hole = hole {
                        TagListNavigation(tags: hole.tags)
                    }
                } footer: {
                    if !endReached {
                        HStack() {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .task {
                            // initial load
                            if self.hole == nil {
                                if targetFloorId != nil { // init from target floor
                                    await loadToTargetFloor()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // hack to give a time redraw
                                        proxy.scrollTo(targetFloorId, anchor: .top) // FIXME: can't `withAnimation`, will cause Fatal error: List update took more than 1 layout cycle to converge
                                    }
                                    return
                                } else { // initial load hole
                                    await loadHoleInfo()
                                }
                            }
                            
                            if floors.isEmpty { // all relevant data present, ready to load floors
                                await loadMoreFloors()
                            }
                        }
                    }
                }
                .textCase(nil)
            }
            .listStyle(.grouped)
            .navigationTitle("#\(String(holeId))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    toolbar
                }
            }
        }
    }
    
    var toolbar: some View {
        Group {
            if hole != nil {
                Button {
                    Task { @MainActor in
                        await toggleFavorites()
                    }
                } label: {
                    Image(systemName: favorited ? "star.fill" : "star")
                }
                
                Button(action: { showReplyPage = true }) {
                    Image(systemName: "arrowshape.turn.up.left")
                }
                .sheet(isPresented: $showReplyPage) {
                    ReplyPage(
                        holeId: holeId,
                        showReplyPage: $showReplyPage,
                        content: "")
                }
            }
        }
    }
}

struct PostPage_Previews: PreviewProvider {
    static var previews: some View {
        PostPage(hole: PreviewDecode.decodeObj(name: "hole")!)
    }
}

