import SwiftUI

struct FDLibraryPage: View {
    var body: some View {
        AsyncContentView {
            return try await FDLibraryAPI.getLibraries()
        } content: { libraries in
            List {
                ForEach(libraries) { library in
                    LabeledContent {
                        VStack {
                            let progress = library.current > library.capacity ? 1.0 : (Double(library.current) / Double(library.capacity))
                            CircularProgressView(progress: progress)
                            Text("\(String(library.current)) / \(String(library.capacity))")
                                .font(.footnote)
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(library.name)
                            Text(library.openTime)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Library Popularity")
        }
    }
}

#Preview {
    NavigationStack {
        FDLibraryPage()
    }
}
