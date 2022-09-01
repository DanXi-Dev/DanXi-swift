import SwiftUI

struct FavoritesPage: View {
    @State var loading = true
    @State var favorites: [THHole] = []
    
    init() { }
    
    init(favorites: [THHole]) { // preview purpose
        self._favorites = State(initialValue: favorites)
        self._loading = State(initialValue: false)
    }
    
    func fetchFavorites() async {
        do {
            self.favorites = try await NetworkRequests.shared.loadFavorites()
            loading = false
        } catch {
            print("DANXI-DEBUG: load favorites")
        }
    }
    
    var body: some View {
        Group {
            if loading {
                ProgressView()
                    .task {
                        await fetchFavorites()
                    }
            } else {
                List {
                    ForEach(favorites) { hole in
                        HoleView(hole: hole)
                    }
                }
                .listStyle(.grouped)
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
