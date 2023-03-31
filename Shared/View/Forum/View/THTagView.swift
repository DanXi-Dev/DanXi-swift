import SwiftUI
import WrappingHStack

struct THTagView: View {
    let name: String
    
    init(_ tag: THTag) {
        self.name = tag.name
    }
    
    init(_ name: String) {
        self.name = name
    }
    
    var body: some View {
        Text(name)
            .textCase(nil)
            .tagStyle(color: randomColor(name))
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
