import SwiftUI
import ViewUtils
import DanXiKit

struct FavoritePage: View {
    var body: some View {
        AsyncContentView { _ in
            try await ForumAPI.listFavorites()
        } content: { favorites in
            FavoritePageContent(favorites)
                .watermark()
        }

    }
}

private struct FavoritePageContent: View {
    @ObservedObject private var favoriteStore = FavoriteStore.shared
    @State private var favorites: [Hole]
    @State private var showAlert = false
    @State private var deleteError = ""
    
    init(_ favorites: [Hole]) {
        self._favorites = State(initialValue: favorites)
    }
    
    private func removeFavorite(_ hole: Hole) {
        Task { @MainActor in
            do {
                try await favoriteStore.toggleFavorite(hole.id)
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
                ForumList {
                    ForEach(favorites) { hole in
                        Section {
                            HoleView(hole: hole)
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
                .alert("Toggle Favorite Failed", isPresented: $showAlert) {} message: {
                    Text(deleteError)
                }
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
    }
}
