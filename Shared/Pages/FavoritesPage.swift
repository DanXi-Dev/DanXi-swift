import SwiftUI

struct FavoritesPage: View {
    @State var favorites: [THHole] = []
    
    @State var loading = true
    @State var finished = false
    @State var initError = ""
    
    init() { }
    
    init(favorites: [THHole]) { // preview purpose
        self._favorites = State(initialValue: favorites)
        self._loading = State(initialValue: false)
        self._finished = State(initialValue: true)
    }
    
    func fetchFavorites() async {
        do {
            self.favorites = try await DXNetworks.shared.loadFavorites()
            finished = true
        } catch {
            initError = error.localizedDescription
        }
    }
    
    func removeFavorites(at offsets: IndexSet) {
        let previousList = favorites
        favorites.remove(atOffsets: offsets) // UI change
        
        Task { // perform server communication
            await withTaskGroup(of: Void.self) { taskGroup in
                offsets.forEach { index in
                    let holeId = previousList[index].id
                    taskGroup.addTask {
                        do {
                            _ = try await DXNetworks.shared.toggleFavorites(holeId: holeId, add: false)
                            // update data model
                            Task { @MainActor in
                                TreeholeDataModel.shared.removeFavorate(holeId)
                            }
                        } catch {
                            print("DANXI-DEBUG: remove favorite failed")
                        }
                    }
                }
            }
        }
    }
    
    
    var body: some View {
        LoadingView(loading: $loading,
                        finished: $finished,
                        errorDescription: initError.description,
                        action: fetchFavorites) {
            List {
                ForEach(favorites) { hole in
                    HoleView(hole: hole)
                }
                .onDelete(perform: removeFavorites)
            }
            .toolbar {
                EditButton()
            }
            .listStyle(.grouped)
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
