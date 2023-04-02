import SwiftUI

struct ListSeparatorWrapper<Content: View>: View {
    let width: CGFloat
    let content: Content
    
    init(width: CGFloat = 5.0, content: () -> Content) {
        self.width = width
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
                .padding(.horizontal)
            Rectangle()
                .fill(.secondary.opacity(0.2))
                .frame(height: width)
        }
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowSeparator(.hidden)
    }
}
