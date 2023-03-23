import SwiftUI

struct THLoaderPage: View {
    let loader: THHoleLoader
    @State var loading = true
    @State var model: THHoleModel?
    
    init(_ loader: THHoleLoader) {
        self.loader = loader
    }

    var body: some View {
        LoadingPage {
            model = try await loader.load()
        } content: {
            if let model = model {
                THHolePage(model)
            }
        }
    }
}
