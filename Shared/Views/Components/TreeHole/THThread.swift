import SwiftUI

struct THThread: View {
    @Environment(\.colorScheme) var colorScheme
    var hole: OTHole
    
    var body: some View {
        ScrollView {
            VStack {
                THPost(floor: hole.firstFloor, tagList: hole.tags)
                
                ForEach(hole.floors[1...]) { floor in
                    THPost(floor: floor)
                }
            }
        }
#if !os(watchOS)
        .background(Color(uiColor: colorScheme == .dark ? .systemBackground : .secondarySystemBackground))
#endif
        .navigationTitle(String(hole.id))
    }
}




struct THThread_Previews: PreviewProvider {
    static let tag = OTTag(id: 1, temperature: 1, name: "Tag")
    
    static let floor = OTFloor(
        id: 1234567, holeId: 123456,
        updateTime: "2022-04-14T08:23:12.761042+08:00",
        createTime: "2022-04-14T08:23:12.761042+08:00",
        like: 12,
        liked: true,
        storey: 5,
        content: """
        Hello, **Dear** readers!
        
        We can make text *italic*, ***bold italic***, or ~~striked through~~.
        
        You can even create [links](https://www.twitter.com/twannl) that actually work.
        
        Or use `Monospace` to mimic `Text("inline code")`.
        
        """,
        poster: "Dax")
    
    static let hole = OTHole(
        id: 123456,
        divisionId: 1,
        view: 15,
        reply: 13,
        updateTime: "2022-04-14T08:23:12.761042+08:00",
        createTime: "2022-04-14T08:23:12.761042+08:00",
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
