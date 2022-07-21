import SwiftUI

struct THThread: View {
    @EnvironmentObject var accountState: THAccountModel
    @Environment(\.colorScheme) var colorScheme
    @State var hole: THHole
    @State var endReached = false
    
    
    var body: some View {
        
        List {
            Section {
                THFloorView(floor: hole.firstFloor, tagList: hole.tags)
                
                ForEach(hole.floors[1...]) { floor in
                    THFloorView(floor: floor)
                }
            } footer: {
                if !endReached {
                    HStack() {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .task {
                        do {
                            let lastStorey = hole.floors.last!.storey // floors will never be empty, as it contains `firstFloor`
                            let newFloors = try await THloadFloors(token: accountState.credential ?? "", holeId: hole.id, startFloor: lastStorey + 1)
                            withAnimation {
                                endReached = newFloors.isEmpty
                                hole.floors.append(contentsOf: newFloors)
                            }
                        } catch {
                            print("load new floors failed")
                        }
                    }
                    
                } else {
                    Text("bottom reached")
                }
            }
        }
#if !os(watchOS)
        .listStyle(.grouped)
#endif
        .navigationTitle("#\(String(hole.id))")
        .navigationBarTitleDisplayMode(.inline)
    }
}




struct THThread_Previews: PreviewProvider {
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
        Group {
            THThread(hole: hole)
            THThread(hole: hole)
                .preferredColorScheme(.dark)
        }
    }
}
