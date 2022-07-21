import SwiftUI

struct THPost: View {
    @Environment(\.colorScheme) var colorScheme
    
    let floor: OTFloor
    let tagList: [OTTag]?
    
    init(floor: OTFloor, tagList: [OTTag]? = nil) {
        self.floor = floor
        self.tagList = tagList
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if let tagList = tagList {
                TagList(tags: tagList)
            }
            poster
            Text(floor.content)
                .font(.system(size: 16))
            info
            Divider()
            actions
        }
        .padding()
#if !os(watchOS)
        .background(Color(uiColor: colorScheme == .dark ? .secondarySystemBackground : .systemBackground))
#endif
        .cornerRadius(13)
        .padding(.horizontal)
        .padding(.vertical, 5.0)
    }
    
    private var poster: some View {
        HStack {
            Rectangle()
                .frame(width: 3, height: 15)
            Text(floor.poster)
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
            Text(floor.createTime)
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
            Spacer()
            Label("点赞 (\(floor.like))", systemImage: floor.liked ?? false ? "heart.fill" : "heart" )
                .foregroundColor(floor.liked ?? false ? .pink : .secondary)
            
            Spacer()
            Label("举报", systemImage: "exclamationmark.circle")
            Spacer()
        }
        .font(.caption2)
        .foregroundColor(.secondary)
    }
}

struct THPost_Previews: PreviewProvider {
    static let floor = OTFloor(
        id: 1234567,
        holeId: 123456,
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

    static let tag = OTTag(id: 1, temperature: 1, name: "Tag")

    static let tagList = Array(repeating: tag, count: 5)

    static var previews: some View {
        Group {
            THPost(floor: floor)
            THPost(floor: floor, tagList: tagList)
            THPost(floor: floor)
                .preferredColorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
    }
}
