import SwiftUI
import ViewUtils

struct THLoaderPage: View {
    let loader: THHoleLoader
    
    init(_ loader: THHoleLoader) {
        self.loader = loader
    }

    var body: some View {
        AsyncContentView { _ in
            return try await loader.load()
        } content: { model in
            THHolePage(model)
        }
    }
}
