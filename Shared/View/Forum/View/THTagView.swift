import SwiftUI
import ViewUtils

struct THTagView: View {
    let name: String
    let color: Color
    let deletable: Bool
    
    init(_ tag: THTag, deletable: Bool = false) {
        self.name = tag.name
        self.color = hashColorForTreehole(tag.name)
        self.deletable = deletable
    }
    
    init(_ name: String, color: Color? = nil, deletable: Bool = false) {
        self.name = name
        self.color = color ?? hashColorForTreehole(name)
        self.deletable = deletable
    }
    
    var body: some View {
        HStack {
            Text(name)
            if deletable {
                Divider()
                Image(systemName: "multiply")
                    .imageScale(.small)
            }
        }
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
