import SwiftUI

struct FavoritesPage: View {
//    let model = TreeholeDataModel.shared
//    @State var favorites: [THHole] = []
//
//    @State var loading = true
//    @State var finished = false
//    @State var initError = ""
//    @State var showAlert = false
//    @State var deleteError = ""
//
//    init() { }
//
//    init(favorites: [THHole]) { // preview purpose
//        self._favorites = State(initialValue: favorites)
//        self._loading = State(initialValue: false)
//        self._finished = State(initialValue: true)
//    }
//
//    func fetchFavorites() async {
//        do {
//            self.favorites = try await DXNetworks.shared.loadFavorites()
//            finished = true
//        } catch {
//            initError = error.localizedDescription
//        }
//    }
//
//    func removeFavorites(at offsets: IndexSet) {
//        let previousList = favorites
//        favorites.remove(atOffsets: offsets) // UI change
//
//        Task { @MainActor in
//            let removeIds = offsets.map { previousList[$0].id }
//            let newIds = model.favorites.filter { !removeIds.contains($0) }
//            do {
//                model.favorites = try await DXNetworks.shared.modifyFavorites(holeIds: newIds)
//            } catch {
//                showAlert = true
//                deleteError = error.localizedDescription
//                favorites = previousList // restore UI change
//            }
//        }
//    }
//
    
    var body: some View {
        Text("TODO")
//        LoadingView(loading: $loading,
//                        finished: $finished,
//                        errorDescription: initError.description,
//                        action: fetchFavorites) {
//            if favorites.isEmpty {
//                Text("Empty Favorites List")
//                    .foregroundColor(.secondary)
//            } else {
//                List {
//                    ForEach(favorites) { hole in
//                        HoleView(hole: hole, listStyle: true)
//                    }
//                    .onDelete(perform: removeFavorites)
//                }
//                .toolbar {
//                    EditButton()
//                }
//                .alert("Toggle Favorite Failed", isPresented: $showAlert) {
//                    Button("OK") { }
//                } message: {
//                    Text(deleteError)
//                }
//                .listStyle(.plain)
//            }
//        }
//        .navigationBarTitleDisplayMode(.inline)
//        .navigationTitle("Favorites")
    }
}

//struct FavoritesPage_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            FavoritesPage(favorites: PreviewDecode.decodeList(name: "hole-list"))
//        }
//    }
//}
