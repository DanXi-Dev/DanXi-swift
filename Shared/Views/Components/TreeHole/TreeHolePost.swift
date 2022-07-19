import SwiftUI

struct TreeHolePost: View {
    let holeId: Int
    let floors: [OTFloor]
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(floors) { floor in
                    TreeHoleCard(floor: floor)
                }
            }
        }
        .navigationTitle("#\(String(holeId))") // You need to explictly specify String(id) to remove the thousand seperator
    }
}




struct TreeHolePost_Previews: PreviewProvider {
    static var testFloor = OTFloor(
        floor_id: 1234567,
        hole_id: 123456,
        like: 12,
        storey: 5,
        content: """
        We can make text *italic*, **bold**, ***bold italic***, or ~~striked through~~.
        
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
    
    static var testFloorList = Array(repeating: testFloor, count: 3)
    
    static var previews: some View {
        Group {
            TreeHolePost(holeId:1234, floors: testFloorList)
            TreeHolePost(holeId:1234, floors: testFloorList)
                .preferredColorScheme(.dark)
        }
    }
}
