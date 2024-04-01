import SwiftUI
import ViewUtils

struct THBackgroundList<Content: View, SelectionValue: Hashable>: View {
    @ObservedObject private var settings = THSettings.shared
    @Binding private var selection: Set<SelectionValue>
    @Binding private var selectable: Bool
    
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
        self._selectable = .constant(false)
    }
    
    init(selection: Binding<Set<SelectionValue>>, selectable: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.content = content()
        self._selection = selection
        self._selectable = selectable
    }
    
    var body: some View {
        if selectable {
            List(selection: $selection) {
                content
            }
            .compactSectionSpacing()
        } else {
            List {
                content
            }
            .compactSectionSpacing()
        }
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
