import SwiftUI
import WrappingHStack

/// View that present a list of tags.
struct TagList: View {
    let tags: [THTag]
    let navigation: Bool
    
    /// Create a Tag List.
    /// - Parameters:
    ///   - tags: tags to display.
    ///   - navigation: whether this view will respond to user tap action and perform navigation.
    init(_ tags: [THTag], navigation: Bool = false) {
        self.tags = tags
        self.navigation = navigation
    }
    
    var body: some View {
        WrappingHStack(tags, lineSpacing: 5.0) { tag in
            tagItem(tag)
        }
    }
    
    @ViewBuilder
    private func tagItem(_ tag: THTag) -> some View {
        if navigation {
            NavigationLink(value: tag) {
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

struct TagView: View {
    let tag: THTag
    
    var body: some View {
        Text(tag.name)
            .textCase(nil)
            .tagStyle(color: randomColor(tag.name))
    }
}

/// Apply special tag style for a piece of text.
struct TagStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let color: Color
    let font: Font
    
    func body(content: Content) -> some View {
        content
            .padding(EdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 10))
            .background(color.opacity(colorScheme == .light ? 0.1 : 0.2))
            .cornerRadius(5)
            .foregroundColor(color)
            .font(font)
            .lineLimit(1)
    }
}

extension View {
    /// Apply special tag style for a piece of text.
    /// - Parameters:
    ///   - color: The color of the tag.
    ///   - font: (Optional) Control the font of the text.
    /// - Returns: A view that applies tag style
    func tagStyle(color: Color, font: Font = .footnote) -> some View {
        modifier(TagStyle(color: color, font: font))
    }
}

struct TagList_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TagList(Bundle.main.decodeData("tags"))
                .previewLayout(.sizeThatFits)
        }
    }
}
