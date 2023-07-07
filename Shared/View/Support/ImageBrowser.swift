import SwiftUI
import AdvancedScrollView

struct ImageWithPopover: View {
    let image: Image
    
    @State private var showBrowser = false
    
    var body: some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .sheet(isPresented: $showBrowser) {
                ImageBrowser(image)
            }
            .onTapGesture {
                showBrowser = true
            }
    }
}

struct ImageBrowser: View {
    let image: Image
    @Environment(\.dismiss) var dismiss
    
    init(_ image: Image) {
        self.image = image
    }
    
    var body: some View {
        NavigationStack {
            AdvancedScrollView { proxy in
                image
            }
            .navigationTitle("View Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .bold()
                    }
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    ShareLink(item: image, preview: SharePreview("", image: image)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

struct Image_Preview: PreviewProvider {
    static var previews: some View {
        ImageBrowser(Image("fsy2001"))
    }
}
