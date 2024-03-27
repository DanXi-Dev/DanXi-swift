import SwiftUI
import ViewUtils

struct THBackgroundList<Content: View, SelectionValue: Hashable>: View {
    @ObservedObject private var settings = THSettings.shared
    @Binding private var selection: Set<SelectionValue>
    private var hasBackground: Bool {
        settings.backgroundImage != nil
    }
    
    private let content: Content
    
    init(@ViewBuilder content: () -> Content) where SelectionValue == Never {
        self.content = content()
        // selection is not needed
        self._selection = Binding(
            get: { Set<Never>()},
            set: { _, _ in })
    }
    
    init(selection: Binding<Set<SelectionValue>>, @ViewBuilder content: () -> Content) {
        self.content = content()
        self._selection = selection
    }
    
    var body: some View {
        List(selection: $selection) {
                content
        }
        .sectionSpacing(10)
//        .scrollContentBackground(hasBackground ? .hidden : .visible)
//        .background(alignment: .bottomLeading) { // leading alignment is used so that the image won't move when the size of List changes during scroll (navigation title may change its size)
//            if let image = settings.backgroundImage {
//                image
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//                    .ignoresSafeArea()
//                    .opacity(0.3)
//            }
//        }
    }
}
