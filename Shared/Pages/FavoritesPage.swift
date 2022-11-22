import SwiftUI

struct FavoritesPage: View {
    @ObservedObject var store = TreeholeStore.shared
    @State var favorites: [THHole] = []

    @State var initError = ""
    @State var showAlert = false
    @State var deleteError = ""

    init() { }

    init(favorites: [THHole]) { // preview purpose
        self._favorites = State(initialValue: favorites)
    }

    func fetchFavorites() async throws {
        self.favorites = try await TreeholeRequests.loadFavorites()
    }

    func removeFavorites(at offsets: IndexSet) {
        let previousList = favorites
        favorites.remove(atOffsets: offsets) // UI change

        Task { @MainActor in
            let removeIds = offsets.map { previousList[$0].id }
            let newIds = store.favorites.filter { !removeIds.contains($0) }
            do {
                store.favorites = try await TreeholeRequests.modifyFavorites(holeIds: newIds)
            } catch {
                showAlert = true
                deleteError = error.localizedDescription
                favorites = previousList // restore UI change
            }
        }
    }

    
    var body: some View {
        LoadingView {
            self.favorites = try await TreeholeRequests.loadFavorites()
        } content: {
            if favorites.isEmpty {
                Text("Empty Favorites List")
                    .foregroundColor(.secondary)
            } else {
                List {
                    ForEach(favorites) { hole in
                        HoleView(hole: hole, listStyle: true)
                    }
                    .onDelete(perform: removeFavorites)
                }
                .listStyle(.plain)
                .toolbar {
                    EditButton()
                }
                .alert("Toggle Favorite Failed", isPresented: $showAlert) {
                    Button("OK") { }
                } message: {
                    Text(deleteError)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Favorites")
    }
}

struct FavoritesPage_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FavoritesPage(favorites: PreviewDecode.decodeList(name: "hole-list"))
        }
    }
}
