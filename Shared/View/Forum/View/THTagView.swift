import SwiftUI
import WrappingHStack

struct THTagView: View {
    let name: String
    let color: Color
    
    init(_ tag: THTag) {
        self.name = tag.name
        self.color = randomColor(tag.name)
    }
    
    init(_ name: String, color: Color? = nil) {
        self.name = name
        self.color = color ?? randomColor(name)
    }
    
    var body: some View {
        Text(name)
            .textCase(nil)
            .tagStyle(color: color)
    }
}

/// Apply special tag style for a piece of text.
struct TagStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let color: Color
    let font: Font
    
    func body(content: Content) -> some View {
        content
            .padding(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
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
    func tagStyle(color: Color, font: Font = .caption2) -> some View {
        modifier(TagStyle(color: color, font: font))
    }
}
