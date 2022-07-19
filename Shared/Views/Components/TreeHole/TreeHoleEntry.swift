import SwiftUI

struct TreeHoleEntry: View {
    let hole: OTHole
    
    var body: some View {
        VStack(alignment: .leading) {
            if let tagList = hole.tags {
                TagList(tags: tagList)
            }
            Text(!hole.floors.prefetch[0].fold!.isEmpty ? "无信息" : hole.floors.prefetch[0].content)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(6)
        }
        .padding()
#if !os(watchOS)
        .background(Color(UIColor.systemGray6))
#endif
        .cornerRadius(13)
        .padding(.horizontal)
        .padding(.vertical, 5.0)
    }
}

struct TreeHoleEntry_Previews: PreviewProvider {
    static let floor = OTFloor(
        floor_id: 1234567,
        hole_id: 123456,
        like: 12,
        storey: 5,
        content: """
        Hello, **SwiftLee** readers!
        
        We can make text *italic*, ***bold italic***, or ~~striked through~~.
        
        You can even create [links](https://www.twitter.com/twannl) that actually work.
        
        Or use `Monospace` to mimic `Text("inline code")`.
        
        """,
        anonyname: "Dax",
        time_updated: "",
        time_created: "3天前",
        deleted: false,
        is_me: false,
        liked: true,
        fold: [])
    
    static let hole = OTHole(
        hole_id: 12345,
        division_id: 1,
        view: 5, reply: 5,
        floors: _OTFloors(last_floor: floor, prefetch: [floor]),
        time_created: "none", time_updated: "none",
        tags: [OTTag(name: "树洞", tag_id: 1, temperature: 0)])
    
    static var previews: some View {
        TreeHoleEntry(hole: hole)
    }
}
