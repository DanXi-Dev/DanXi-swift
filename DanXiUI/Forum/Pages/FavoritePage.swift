import SwiftUI
import ViewUtils
import DanXiKit

struct FavoritePage: View {
    var body: some View {
        AsyncContentView {
            let holes = try await ForumAPI.listFavorites()
            return holes.map { HolePresentation(hole: $0) }
        } content: { favorites in
            FavoritePageContent(favorites)
                .watermark()
        }
    }
}

private struct FavoritePageContent: View {
    @ObservedObject private var favoriteStore = FavoriteStore.shared
    @State private var favorites: [HolePresentation]
    @State private var showAlert = false
    @State private var deleteError = ""
    
    init(_ favorites: [HolePresentation]) {
        self._favorites = State(initialValue: favorites)
    }
    
    private func removeFavorite(_ presentation: HolePresentation) {
        Task { @MainActor in
            do {
                try await favoriteStore.toggleFavorite(presentation.id)
                let idx = favorites.firstIndex(where: { $0.id == presentation.id })
                if let idx {
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
                    ForEach(favorites) { presentation in
                        Section {
                            HoleView(presentation: presentation)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        removeFavorite(presentation)
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
