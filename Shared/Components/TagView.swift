import SwiftUI

/// View that present a list of tags.
struct TagList: View {
    let tags: [THTag]
    let lineWrap: Bool
    let navigation: Bool
    
    /// Create a Tag List.
    /// - Parameters:
    ///   - tags: tags to display.
    ///   - lineWrap: whether to start a new line when horizontal space is insufficient.
    ///   - navigation: whether this view will respond to user tap action and perform navigation.
    init(_ tags: [THTag], lineWrap: Bool = false, navigation: Bool = false) {
        self.tags = tags
        self.lineWrap = lineWrap
        self.navigation = navigation
    }
    
    var body: some View {
        if lineWrap {
            FlexibleView(data: tags, spacing: 5.0, alignment: .leading) { tag in
                tagItem(tag)
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 5.0) {
                    ForEach(tags) { tag in
                        tagItem(tag)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func tagItem(_ tag: THTag) -> some View {
        if navigation {
            NavigationLink {
                SearchTagPage(tagname: tag.name)
            } label: {
                Text(tag.name)
                    .textCase(nil) // prevent capitalization in list header
                    .tagStyle(color: randomColor(tag.name))
            }
            .buttonStyle(.borderless)
        } else {
            Text(tag.name)
                .textCase(nil) // prevent capitalization in list header
                .tagStyle(color: randomColor(tag.name))
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
