import SwiftUI

struct THBackgroundList<Content: View>: View {
    @ObservedObject private var settings = THSettings.shared
    private var hasBackground: Bool {
        settings.backgroundImage != nil
    }
    
    private let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        List {
            content
                .listRowBackground(Color.clear.opacity(0))
        }
        .listStyle(.inset)
        .scrollContentBackground(hasBackground ? .hidden : .visible)
        .background(alignment: .leading) { // leading alignment is used so that the image won't move when the size of List changes during scroll (navigation title may change its size)
            if let image = settings.backgroundImage {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .opacity(0.3)
            }
        }
    }
}
