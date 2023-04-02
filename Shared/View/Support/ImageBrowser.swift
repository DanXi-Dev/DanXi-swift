import SwiftUI
import AdvancedScrollView

struct ImageWithPopover: View {
    let image: Image
    
    @State var showBrowser = false
    
    var body: some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .fullScreenCover(isPresented: $showBrowser) {
                ImageBrowser(image)
            }
            .onTapGesture {
                showBrowser = true
            }
    }
}

struct ImageBrowser: View {
    let image: Image
    @State var hideToolbar = false
    @Environment(\.dismiss) var dismiss
    
    init(_ image: Image) {
        self.image = image
    }
    
    var body: some View {
        NavigationStack {
            AdvancedScrollView { proxy in
                image
            }
            .ignoresSafeArea()
            .navigationTitle("View Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(hideToolbar ? .hidden : .visible, for: .navigationBar)
            .onTapGesture {
                withAnimation {
                    hideToolbar.toggle()
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    ShareLink(item: image, preview: SharePreview("", image: image)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .bold()
                    }
                }
            }
        }
    }
}
