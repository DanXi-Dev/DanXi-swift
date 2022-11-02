import SwiftUI
import Foundation

/// Main page of treehole section.
struct TreeholePage: View {
    @ObservedObject var store = TreeholeStore.shared
    let holes: [THHole]
    
    @State var searchText = ""
    @State var searchSubmitted = false
    
    @State var loading = !TreeholeStore.shared.initialized
    @State var initFinished = TreeholeStore.shared.initialized
    @State var initError = ""
    
    /// Default initializer.
    init() {
        self.holes = []
    }
    
    /// Creates a preview.
    init(divisions: [THDivision], holes: [THHole]) {
        self.holes = holes
        self._initFinished = State(initialValue: true)
        TreeholeStore.shared.divisions = divisions
    }
    
    func initialLoad() async {
        do {
            try await store.loadAll()
        } catch {
            initError = error.localizedDescription
        }
    }
    
    var body: some View {
        LoadingView(loading: $loading,
                    finished: $store.initialized,
                    errorDescription: initError,
                    action: initialLoad) {
            DelegatePage(holes: holes, $searchText, $searchSubmitted)
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
                .onSubmit(of: .search) {
                    searchSubmitted = true
                }
        }
    }
    
    
}

/// Searchable delegation, switch between main view and search view based on searchbar status.
struct DelegatePage: View {
    @Environment(\.isSearching) var isSearching
    @Binding var searchText: String
    @Binding var searchSubmitted: Bool
    
    @StateObject var viewModel: BrowseViewModel
    
    init(holes: [THHole] = [], _ searchText: Binding<String>, _ searchSubmitted: Binding<Bool>) {
        self._viewModel = StateObject(wrappedValue: BrowseViewModel(holes: holes))
        self._searchText = searchText
        self._searchSubmitted = searchSubmitted
    }
    
    
    var body: some View {
        Group {
            if isSearching {
                SearchPage(searchText: $searchText,
                           searchSubmitted: $searchSubmitted)
            } else {
                BrowsePage()
                    .environmentObject(viewModel)
            }
        }
    }
}

struct TreeholePage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                TreeholePage(divisions: PreviewDecode.decodeList(name: "divisions"),
                             holes: PreviewDecode.decodeList(name: "hole-list"))
            }
        }
    }
}
