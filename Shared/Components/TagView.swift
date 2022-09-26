import SwiftUI

/// View that present a list of tags.
struct TagList: View {
    let tags: [THTag]
    let lineWrap: Bool
    
    @State var navActive = false
    @State var navTagName = ""
    
    /// Create a Tag List.
    /// - Parameters:
    ///   - tags: tags to display.
    ///   - lineWrap: whether to start a new line when horizontal space is insufficient.
    init(_ tags: [THTag], lineWrap: Bool = true) {
        self.tags = tags
        self.lineWrap = lineWrap
    }
    
    var body: some View {
        if lineWrap {
            FlexibleView(data: tags, spacing: 5.0, alignment: .leading) { tag in
                tagItem(tag)
            }
            .backgroundLink($navActive) {
                SearchTagPage(tagname: navTagName)
            }
        } else {
            HStack(alignment: .center, spacing: 5.0) {
                ForEach(tags) { tag in
                    tagItem(tag)
                }
            }
            .backgroundLink($navActive) {
                SearchTagPage(tagname: navTagName)
            }
        }
    }
    
    private func tagItem(_ tag: THTag) -> some View {
        Button {
            navTagName = tag.name
            navActive = true
        } label: {
            Text(tag.name)
                .textCase(nil) // prevent capitalization in list header
                .tagStyle(color: randomColor(tag.name))
        }
        .buttonStyle(.borderless)
    }
}


struct TagListNavigation: View {
    let tags: [THTag]
    
    var body: some View {
        HStack(alignment: .center, spacing: 5.0) {
            ForEach(tags) { tag in
                NavigationLink(destination: SearchTagPage(tagname: tag.name)) {
                    Text(tag.name)
                        .tagStyle(color: randomColor(tag.name))
                }
            }
        }
    }
}

/// Apply special tag style for a piece of text.
struct TagStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let color: Color
    let fontSize: CGFloat
    
    func body(content: Content) -> some View {
        content
            .padding(EdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 10))
            .background(color.opacity(colorScheme == .light ? 0.1 : 0.2))
            .cornerRadius(5)
            .foregroundColor(color)
            .font(.system(size: fontSize))
            .lineLimit(1)
    }
}

extension View {
    /// Apply special tag style for a piece of text.
    /// - Parameters:
    ///   - color: The color of the tag.
    ///   - fontSize: (Optional) Control the font size of the text.
    /// - Returns: A view that applies tag style
    func tagStyle(color: Color, fontSize: CGFloat = 14) -> some View {
        modifier(TagStyle(color: color, fontSize: fontSize))
    }
}

struct TagList_Previews: PreviewProvider {    
    static var previews: some View {
        TagList(PreviewDecode.decodeList(name: "tags"))
            .previewLayout(.sizeThatFits)
    }
}
