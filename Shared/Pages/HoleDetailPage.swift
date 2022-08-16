import SwiftUI

struct HoleDetailPage: View {
    @State var hole: THHole?
    @State var floors: [THFloor] = []
    @State var endReached = false
    @State var favorited: Bool
    @State var holeId: Int?
    var targetFloorId: Int? = nil
    
    @State var errorPresenting = false
    @State var errorInfo = ErrorInfo()
    
    init(hole: THHole) {
        self._hole = State(initialValue: hole)
        self._favorited = State(initialValue: TreeholeDataModel.shared.user?.favorites.contains(hole.id) ?? false)
        self._holeId = State(initialValue: hole.id)
        self._floors = State(initialValue: hole.floors)
    }
    
    init(holeId: Int) { // init from hole ID, load info afterwards
        self._hole = State(initialValue: nil)
        self._favorited = State(initialValue: TreeholeDataModel.shared.user?.favorites.contains(holeId) ?? false)
        self._holeId = State(initialValue: holeId)
    }
    
    init(targetFloorId: Int) { // init from floor ID, scroll to that floor
        self.targetFloorId = targetFloorId
        self._hole = State(initialValue: nil)
        self._holeId = State(initialValue: nil)
        self._favorited = State(initialValue: false)
    }
    
    @State var showReplyPage = false
    
    func initialLoad(proxy: ScrollViewProxy) async {
        if holeId == nil && targetFloorId != nil {
            await loadToTargetFloor()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // hack to give a time redraw
                proxy.scrollTo(targetFloorId, anchor: .top) // FIXME: can't `withAnimation`, will cause Fatal error: List update took more than 1 layout cycle to converge
            }
            return
        }
        
        guard let holeId = holeId else {
            return
        }
        
        // load hole info
        do {
            hole = try await NetworkRequests.shared.loadHoleById(holeId: holeId)
        } catch NetworkError.notFound {
            errorInfo = ErrorInfo(title: "Treehole Not Exist", description: "Treehole ID \(String(holeId)) not exist")
            errorPresenting = true
            return
        } catch let error as NetworkError {
            errorInfo = error.localizedErrorDescription
            errorPresenting = true
            return
        } catch {
            print("DANXI-DEBUG: load hole info failed")
        }
        
        if floors.isEmpty { // all relevant data present, ready to load floors
            await loadMoreFloors()
        }
        
        Task { // update viewing number in background task
            do {
                try await NetworkRequests.shared.updateViews(holeId: holeId)
            } catch {
                print("DANXI-DEBUG: update views failed")
            }
        }
    }
    
    func loadMoreFloors() async {
        guard let holeId = holeId else {
            return
        }
        
        do {
            let newFloors = try await NetworkRequests.shared.loadFloors(holeId: holeId, startFloor: floors.count)
            floors.append(contentsOf: newFloors)
            endReached = newFloors.isEmpty
        } catch {
            print("DANXI-DEBUG: load more floors failed")
        }
    }
    
    func loadToTargetFloor() async {
        guard let targetFloorId = targetFloorId else {
            return
        }
        
        do {
            let targetFloor = try await NetworkRequests.shared.loadFloorById(floorId: targetFloorId)
                
            self.holeId = targetFloor.holeId
            self.hole = try await NetworkRequests.shared.loadHoleById(holeId: targetFloor.holeId)
            
            var newFloors: [THFloor] = []
            var floors: [THFloor] = []
            repeat {
                newFloors = try await NetworkRequests.shared.loadFloors(holeId: targetFloor.holeId, startFloor: floors.count)
                floors.append(contentsOf: newFloors)
                if newFloors.contains(targetFloor) {
                    break
                }
            } while !newFloors.isEmpty
            self.floors = floors // insert to view at last, preventing automatic refresh causing URLSession to cancel
        } catch {
            
        }
    }
    
    func toggleFavorites() async {
        guard let holeId = holeId else {
            return
        }
        
        do {
            let favorites = try await NetworkRequests.shared.toggleFavorites(holeId: holeId, add: !favorited)
            TreeholeDataModel.shared.updateFavorites(favorites: favorites)
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
                            .textCase(nil)
                    }
                } footer: {
                    if !endReached {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .task {
                            await initialLoad(proxy: proxy)
                        }
                    }
                }
            }
            .listStyle(.grouped)
            .navigationTitle("#\(String(holeId ?? 0))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    toolbar
                }
            }
            .alert(errorInfo.title, isPresented: $errorPresenting) {
                Button("OK") { }
            } message: {
                Text(errorInfo.description)
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
                        holeId: holeId ?? 0,
                        showReplyPage: $showReplyPage,
                        content: "")
                }
            }
        }
    }
}

struct PostPage_Previews: PreviewProvider {
    static var previews: some View {
        HoleDetailPage(hole: PreviewDecode.decodeObj(name: "hole")!)
    }
}

