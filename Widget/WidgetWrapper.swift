import SwiftUI

/// A wrapper to satisfy widget requirements on older and newer iOS
///
/// On newer iOS, you are required to add a `containerBackground` modifier to widgets, and a padding is automatically added.
/// Meanwhile, on older iOS, the padding is not applied by default, and `containerBackground` API is not available.
/// This view unifies these wrappers, and add a default failed view.
struct WidgetWrapper<Content: View>: View {
    let failed: Bool
    let content: () -> Content
    
    var body: some View {
        if #available(iOS 17, *) {
            widgetContent
                .containerBackground(.fill.quinary, for: .widget)
        } else {
            widgetContent
                .padding()
        }
    }
    
    @ViewBuilder
    private var widgetContent: some View {
        if failed {
            Text("Load Failed")
                .foregroundColor(.secondary)
        } else {
            content()
        }
    }
}
