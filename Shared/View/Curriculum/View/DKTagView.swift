import SwiftUI

struct DKTagView<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .textCase(nil)
            .font(.footnote)
            .lineLimit(1)
            .padding(EdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 10))
            .background(.accentColor.opacity(colorScheme == .light ? 0.1 : 0.2))
            .cornerRadius(5)
            .foregroundColor(.accentColor)
    }
}
