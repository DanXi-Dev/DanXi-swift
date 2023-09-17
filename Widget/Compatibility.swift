import SwiftUI

struct CompatibilityWidget<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        if #available(iOSApplicationExtension 17.0, *) {
            content.containerBackground(for: .widget) {
                EmptyView()
            }
        } else {
            content
        }
    }
}

struct CompatibilityPadding<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        if #available(iOSApplicationExtension 17.0, *) {
            content
        } else {
            content.padding()
        }
    }
}
