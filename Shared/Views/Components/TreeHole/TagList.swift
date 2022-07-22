import SwiftUI

struct TagList: View {
    @Environment(\.colorScheme) var colorScheme
    
    let color = Color.pink
    let tags: [THTag]
    
    var body: some View {
        FlexibleView(data: tags, spacing: 5.0, alignment: .leading) { tag in
            Text(tag.name)
                .padding(EdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 10))
                .background(color.opacity(colorScheme == .light ? 0.1 : 0.2))
                .cornerRadius(5)
                .foregroundColor(color)
                .font(.system(size: 14))
                .lineLimit(1)
        }
    }
}

struct TagList_Previews: PreviewProvider {
    static let tag = THTag(id: 1, temperature: 1, name: "测试标签")
    
    static let shortList = Array(repeating: tag, count: 2)
    
    static let longList = Array(repeating: tag, count: 15)
    
    static var previews: some View {
        Group {
            TagList(tags: shortList)
            TagList(tags: longList)
            TagList(tags: longList)
                .preferredColorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
    }
}
