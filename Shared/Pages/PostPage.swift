import SwiftUI

struct PostPage: View {
    let hole: THHole
    @State var floors: [THFloor] = []
    @State var endReached = false
    
    @State var showReplyPage = false
    
    func loadMoreFloors() async {
        do {
            let newFloors = try await networks.loadFloors(holeId: hole.id, startFloor: floors.count)
            floors.append(contentsOf: newFloors)
            endReached = newFloors.isEmpty
        } catch {
            print("DANXI-DEBUG: load floors failed")
        }
    }
    
    var body: some View {
        List {
            Section {
                ForEach(floors) { floor in
                    FloorView(floor: floor)
                        .task {
                            if floor == floors.last {
                                await loadMoreFloors()
                            }
                        }
                }
            } header: {
                TagListSimple(tags: hole.tags)
            } footer: {
                if !endReached {
                    HStack() {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .task {
                        if floors.isEmpty {
                            await loadMoreFloors()
                        }
                    }
                }
            }
            .textCase(nil)
        }
        .listStyle(.grouped)
        .navigationTitle("#\(String(hole.id))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup {
                Button(action: { showReplyPage = true }) {
                    Image(systemName: "arrowshape.turn.up.left")
                }
                .sheet(isPresented: $showReplyPage) {
                    ReplyPage(
                        holeId: hole.id,
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

