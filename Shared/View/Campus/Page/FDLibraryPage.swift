import SwiftUI
import FudanKit

struct FDLibraryPage: View {
    var body: some View {
        AsyncContentView {
            return try await LibraryAPI.getLibrary()
        } content: { libraries in
            List {
                ForEach(libraries) { library in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(library.name)
                            Text(library.openTime)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .center) {
                            let progress = library.current > library.capacity ? 1.0 : (Double(library.current) / Double(library.capacity))
                            CircularProgressView(progress: progress)
                            Text("\(String(library.current)) / \(String(library.capacity))")
                                .font(.footnote)
                        }
                        .frame(minWidth: 80) // for alignment
                    }
                }
            }
            .navigationTitle("Library Popularity")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    NavigationStack {
        FDLibraryPage()
    }
}
