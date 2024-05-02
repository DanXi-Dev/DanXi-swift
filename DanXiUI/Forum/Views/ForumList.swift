import SwiftUI
import ViewUtils

struct ForumList<Content: View>: View {
    @Environment(\.defaultMinListRowHeight) private var defaultMinListRowHeight
    private let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        List {
            content
                .environment(\.defaultMinListRowHeight, defaultMinListRowHeight)
        }
        // defaultMinListRowHeight is a custom modifier that reduces the height of list items
        // this property should be adjusted based the listRowInsets of the content
        .environment(\.defaultMinListRowHeight, 35)
        .compactSectionSpacing()
    }
}
