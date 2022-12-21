import SwiftUI
import Foundation

/// Main page of treehole section.
struct THHomePage: View {
    @ObservedObject var store = TreeholeStore.shared
    let holes: [THHole]
    
    @State var searchText = ""
    @State var searchSubmitted = false
    @StateObject var router = NavigationRouter()
    
    /// Default initializer.
    init() {
        self.holes = []
    }
    
    /// Creates a preview.
    init(holes: [THHole]) {
        self.holes = holes
    }
    
    
    var body: some View {
        NavigationStack(path: $router.path) {
            LoadingPage(finished: store.initialized) {
                try await store.loadAll()
                try await UserStore.shared.updateUser()
            } content: {
                DelegatePage(holes: holes, $searchText, $searchSubmitted)
                    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
                    .onSubmit(of: .search) {
                        searchSubmitted = true
                    }
            }
                        .navigationDestination(for: THHole.self) { hole in
                            THDetailPage(hole: hole)
                                .environmentObject(router)
                        }
                        .navigationDestination(for: THTag.self) { tag in
                            THSearchTagPage(tagname: tag.name)
                                .environmentObject(router)
                        }
                        .navigationDestination(for: THFloor.self) { floor in
                            THDetailPage(floorId: floor.id)
                                .environmentObject(router)
                        }
                        .navigationDestination(for: TreeholeStaticPages.self) { page in
                            switch page {
                            case .favorites: THFavoritesPage().environmentObject(router)
                            case .reports: THReportPage().environmentObject(router)
                            case .tags: TagsPage().environmentObject(router)
                            case .searchText(let keyword): THSearchTextPage(keyword: keyword).environmentObject(router)
                            case .searchTag(let tag): THSearchTagPage(tagname: tag).environmentObject(router)
                            }
                        }
                        
        }
        .environmentObject(router)
    }
}

enum TreeholeStaticPages: Hashable {
    case favorites, reports, tags
//    case searchText(let text:
    case searchText(keyword: String)
    case searchTag(tag: String)
}

/// Searchable delegation, switch between main view and search view based on searchbar status.
struct DelegatePage: View {
    @Environment(\.isSearching) var isSearching
    @Binding var searchText: String
    @Binding var searchSubmitted: Bool
    
    @StateObject var viewModel: THBrowseModel
    
    init(holes: [THHole] = [], _ searchText: Binding<String>, _ searchSubmitted: Binding<Bool>) {
        self._viewModel = StateObject(wrappedValue: THBrowseModel(holes: holes))
        self._searchText = searchText
        self._searchSubmitted = searchSubmitted
    }
    
    
    var body: some View {
        Group {
            if isSearching {
                THSearchPage(searchText: $searchText,
                           searchSubmitted: $searchSubmitted)
            } else {
                THBrowsePage()
                    .environmentObject(viewModel)
            }
        }
    }
}

struct THHomePage_Previews: PreviewProvider {
    static var previews: some View {
        AuthDelegate.shared.isLogged = true
        TreeholeStore.shared.initialized = true
        TreeholeStore.shared.divisions = Bundle.main.decodeData("divisions")
        
        return THHomePage(holes: Bundle.main.decodeData("hole-list"))
    }
}
