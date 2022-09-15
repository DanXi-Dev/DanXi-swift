import SwiftUI
import Foundation

/// Main page of treehole section.
struct TreeholePage: View {
    @ObservedObject var dataModel = TreeholeDataModel.shared
    
    @State var searchText = ""
    @State var searchSubmitted = false
    
    @State var loading = !TreeholeDataModel.shared.initialized
    @State var initFinished = TreeholeDataModel.shared.initialized
    @State var initError = ""
    
    let holes: [THHole] // for preview purpose
    
    /// Default initializer.
    init() {
        holes = []
    }
    
    /// Creates a preview.
    init(divisions: [THDivision], holes: [THHole]) {
        self._initFinished = State(initialValue: true)
        TreeholeDataModel.shared.divisions = divisions
        self.holes = holes
    }
    
    func initialLoad() async {
        do {
            try await dataModel.fetchInfo()
            initFinished = true
        } catch {
            initError = error.localizedDescription
        }
    }
    
    var body: some View {
        LoadingView(loading: $loading,
                        finished: $initFinished,
                        errorDescription: initError,
                        action: initialLoad) {
            DelegatePage(searchText: $searchText,
                         searchSubmitted: $searchSubmitted,
                         holes: holes)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
            .onSubmit(of: .search) {
                searchSubmitted = true
            }
        }
    }
    
    
}

/// Searchable delegation, switch between main view and search view based on searchbar status
struct DelegatePage: View {
    @Environment(\.isSearching) var isSearching
    @Binding var searchText: String
    @Binding var searchSubmitted: Bool

    let holes: [THHole]
    
    var body: some View {
        Group {
            if isSearching {
                SearchPage(searchText: $searchText,
                           searchSubmitted: $searchSubmitted)
            } else {
                BrowsePage(holes: holes)
            }
        }
    }
}

struct TreeholePage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                TreeholePage(divisions: PreviewDecode.decodeList(name: "divisions"), holes: PreviewDecode.decodeList(name: "hole-list"))
            }
            NavigationView {
                TreeholePage(divisions: PreviewDecode.decodeList(name: "divisions"), holes: PreviewDecode.decodeList(name: "hole-list"))
            }
            .preferredColorScheme(.dark)
        }
    }
}
