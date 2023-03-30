import SwiftUI

struct THFavoritesPage: View {
    @ObservedObject var appModel = DXModel.shared
    @State var favorites: [THHole] = []

    @State var initError = ""
    @State var showAlert = false
    @State var deleteError = ""

    func fetchFavorites() async throws {
        self.favorites = try await THRequests.loadFavorites()
    }
    
    func removeFavorite(_ hole: THHole) {
        Task { @MainActor in
            do {
                try await appModel.toggleFavorite(hole.id)
                if let idx = favorites.firstIndex(of: hole) {
                    favorites.remove(at: idx)
                }
            } catch {
                showAlert = true
                deleteError = error.localizedDescription
            }
        }
    }

    
    var body: some View {
        LoadingPage {
            self.favorites = try await THRequests.loadFavorites()
        } content: {
            if favorites.isEmpty {
                Text("Empty Favorites List")
                    .foregroundColor(.secondary)
            } else {
                List {
                    ForEach(favorites) { hole in
                        THHoleView(hole: hole)
                            .swipeActions {
                                Button(role: .destructive) {
                                    removeFavorite(hole)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .alert("Toggle Favorite Failed", isPresented: $showAlert) {
                    Button("OK") { }
                } message: {
                    Text(deleteError)
                }
            }
        }
        .navigationTitle("Favorites")
    }
}
