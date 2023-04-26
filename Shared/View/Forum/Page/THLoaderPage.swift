import SwiftUI

struct THLoaderPage: View {
    let loader: THHoleLoader
    
    init(_ loader: THHoleLoader) {
        self.loader = loader
    }

    var body: some View {
        AsyncContentView {
            
            return try await loader.load()
        } content: { model in
            THHolePage(model)
        }
    }
}
