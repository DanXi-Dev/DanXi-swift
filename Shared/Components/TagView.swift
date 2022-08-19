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
    let tags: [THTag]
    
    var body: some View {
        FlexibleView(data: tags, spacing: 5.0, alignment: .leading) { tag in
            Text(tag.name)
                .tagStyle(color: randomColor(name: tag.name))
        }
    }
}

struct TagListSimple: View {
    let tags: [THTag]
    
    var body: some View {
        HStack(alignment: .center, spacing: 5.0) {
            ForEach(tags) { tag in
                Text(tag.name)
                    .tagStyle(color: randomColor(name: tag.name))
            }
        }
    }
}


struct TagListNavigation: View {
    let tags: [THTag]
    
    var body: some View {
        HStack(alignment: .center, spacing: 5.0) {
            ForEach(tags) { tag in
                NavigationLink(destination: SearchTagPage(tagname: tag.name, divisionId: nil)) {
                    Text(tag.name)
                        .tagStyle(color: randomColor(name: tag.name))
                }
            }
        }
    }
}


struct TagList_Previews: PreviewProvider {    
    static var previews: some View {
        Group {
            TagList(tags: PreviewDecode.decodeList(name: "tags"))
            TagList(tags: PreviewDecode.decodeList(name: "tags"))
                .preferredColorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
    }
}
