import SwiftUI

struct TagStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let color: Color
    let fontSize: CGFloat
    
    func body(content: Content) -> some View {
            return content
                .padding(EdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 10))
                .background(color.opacity(colorScheme == .light ? 0.1 : 0.2))
                .cornerRadius(5)
                .foregroundColor(color)
                .font(.system(size: fontSize))
                .lineLimit(1)
    }
}

extension View {
    func tagStyle(color: Color, fontSize: CGFloat = 14) -> some View {
        modifier(TagStyle(color: color, fontSize: fontSize))
    }
}

struct TagList: View {
    let color = Color.pink
    let tags: [THTag]
    
    var body: some View {
        FlexibleView(data: tags, spacing: 5.0, alignment: .leading) { tag in
            Text(tag.name)
                .tagStyle(color: color)
        }
    }
}

struct TagListSimple: View {
    let color = Color.pink
    let tags: [THTag]
    
    var body: some View {
        HStack(alignment: .center, spacing: 5.0) {
            ForEach(tags) { tag in
                Text(tag.name)
                    .tagStyle(color: color)
            }
        }
    }
}



struct TagList_Previews: PreviewProvider {
    static let tag = THTag(id: 1, temperature: 1, name: "Test")
    
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
