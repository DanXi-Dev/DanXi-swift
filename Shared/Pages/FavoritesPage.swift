import SwiftUI

struct FavoritesPage: View {
    @State var loading = true
    @State var favorites: [THHole] = []
    
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
                            .background(NavigationLink("", destination: HoleDetailPage(hole: hole)).opacity(0))
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
            FavoritesPage()
        }
    }
}
