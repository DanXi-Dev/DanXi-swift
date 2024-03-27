import SwiftUI
import ViewUtils

struct THFavoritesPage: View {
    var body: some View {
        AsyncContentView {
            try await THRequests.loadFavorites()
        } content: { favorites in
            FavoritePageContent(favorites)
        }
    }
}

private struct FavoritePageContent: View {
    @ObservedObject private var appModel = THModel.shared
    @State private var favorites: [THHole]
    @State private var showAlert = false
    @State private var deleteError = ""
    
    init(_ favorites: [THHole]) {
        self._favorites = State(initialValue: favorites)
    }
    
    private func removeFavorite(_ hole: THHole) {
        Task { @MainActor in
            do {
                try await appModel.toggleFavorite(hole.id)
                if let idx = favorites.firstIndex(of: hole) {
                    favorites.remove(at: idx)
                }
            } catch {
                deleteError = error.localizedDescription
                showAlert = true
            }
        }
    }
    
    var body: some View {
        Group {
            if favorites.isEmpty {
                Text("Empty Favorites List")
                    .foregroundColor(.secondary)
            } else {
                THBackgroundList {
                    ForEach(favorites) { hole in
                        Section {
                            THHoleView(hole: hole)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        removeFavorite(hole)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        }
                    }
                }
                .sectionSpacing(10)
                .alert("Toggle Favorite Failed", isPresented: $showAlert) {} message: {
                    Text(deleteError)
                }
            }
        }
        .navigationTitle("Favorites")
    }
}
