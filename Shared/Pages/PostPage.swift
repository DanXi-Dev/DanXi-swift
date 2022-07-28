import SwiftUI

struct PostPage: View {
    let hole: THHole
    @State var floors: [THFloor] = []
    @State var endReached = false
    
    
    
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
    }
}

struct PostPage_Previews: PreviewProvider {
    static let tag = THTag(id: 1, temperature: 1, name: "Tag")
    
    static let floor = THFloor(
        id: 1234567, holeId: 123456,
        iso8601UpdateTime: "2022-04-14T08:23:12.761042+08:00",
        iso8601CreateTime: "2022-04-14T08:23:12.761042+08:00", updateTime: Date.now,
        createTime: Date.now,
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
    
    static var previews: some View {
        PostPage(hole: hole)
    }
}

