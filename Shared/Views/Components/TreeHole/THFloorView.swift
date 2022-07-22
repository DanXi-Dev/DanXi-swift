import SwiftUI

struct THFloorView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let floor: THFloor
    
    var body: some View {
        VStack(alignment: .leading) {
            poster
            Text(floor.content)
                .font(.system(size: 16))
            info
//            actions
        }
    }
    
    private var poster: some View {
        HStack {
            Rectangle()
                .frame(width: 3, height: 15)
            Text(floor.posterName)
                .font(.system(size: 15))
                .fontWeight(.bold)
        }
        .foregroundColor(.red)
    }
    
    private var info: some View {
        HStack {
            Text("\(floor.storey + 1)F")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            Text("(##\(String(floor.id)))")
                .font(.caption2)
                .foregroundColor(.secondary)
#if !os(watchOS)
                .foregroundColor(Color(uiColor: .systemGray2))
#endif
            
            Spacer()
            Text(floor.createTime.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
#if !os(watchOS)
                .foregroundColor(Color(uiColor: .systemGray2))
#endif
        }
        .padding(.top, 2.0)
    }
    
    private var actions: some View {
        HStack {
            Label(String(floor.like), systemImage: floor.liked ?? false ? "heart.fill" : "heart" )
                .foregroundColor(floor.liked ?? false ? .pink : .secondary)
            Label("举报", systemImage: "exclamationmark.circle")
        }
        .padding(.top, 4.0)
        .font(.caption2)
        .foregroundColor(.secondary)
    }
}

struct THPost_Previews: PreviewProvider {
    
    static let floor = THFloor(
        id: 1234567,
        holeId: 123456,
        iso8601UpdateTime: "2022-04-14T08:23:12.761042+08:00",
        iso8601CreateTime: "2022-04-14T08:23:12.761042+08:00",
        updateTime: Date.now, createTime: Date.now,
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

    static var previews: some View {
        Group {
            THFloorView(floor: floor)
            THFloorView(floor: floor)
                .preferredColorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
    }
}
