import SwiftUI

struct PostPage: View {
    @State var hole: THHole?
    @State var floors: [THFloor] = []
    @State var endReached = false
    @State var bookmarked: Bool
    let holeId: Int
    
    init(hole: THHole) {
        self._hole = State(initialValue: hole)
        self._bookmarked = State(initialValue: treeholeDataModel.user?.favorites.contains(hole.id) ?? false)
        self.holeId = hole.id
    }
    
    init(holeId: Int) { // init from hole ID, load info afterwards
        self._hole = State(initialValue: nil)
        self._bookmarked = State(initialValue: treeholeDataModel.user?.favorites.contains(holeId) ?? false)
        self.holeId = holeId
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
    
    func toggleBookmark() async {
        do {
            let bookmarks = try await networks.toggleFavorites(holeId: holeId, add: !bookmarked)
            treeholeDataModel.updateBookmarks(bookmarks: bookmarks)
            bookmarked = bookmarks.contains(holeId)
        } catch {
            print("DANXI-DEBUG: toggle bookmark failed")
        }
    }
    
    var body: some View {
        List {
            Section {
                ForEach(floors) { floor in
                    FloorView(floor: floor, isPoster: floor.posterName == hole?.firstFloor.posterName ?? "")
                        .task {
                            if floor == floors.last {
                                await loadMoreFloors()
                            }
                        }
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
                        if self.hole == nil {
                            await loadHoleInfo()
                        }
                        if floors.isEmpty {
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
    
    var toolbar: some View {
        Group {
            
            Button(action: { showReplyPage = true }) {
                Image(systemName: "arrowshape.turn.up.left")
            }
            .sheet(isPresented: $showReplyPage) {
                ReplyPage(
                    holeId: holeId,
                    showReplyPage: $showReplyPage,
                    content: "")
            }
            
            Button {
                Task { @MainActor in
                    await toggleBookmark()
                }
            } label: {
                Image(systemName: bookmarked ? "bookmark.fill" : "bookmark")
            }
            
        }
    }
}

struct PostPage_Previews: PreviewProvider {
    static var previews: some View {
        PostPage(hole: PreviewDecode.decodeObj(name: "hole")!)
    }
}

