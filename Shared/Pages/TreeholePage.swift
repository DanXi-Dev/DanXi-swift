import SwiftUI
import Foundation

/// Main page of treehole section
struct TreeholePage: View {
    @State var divisions: [THDivision] = []
    
    @State var searchText = ""
    @State var searchSubmitted = false
    
    @State var loading = true
    @State var initFinished = false
    @State var initError = ErrorInfo()
    
    let holes: [THHole] // for preview purpose
    
    /// Default initializer
    init() {
        holes = []
    }
    
    /// Creates a preview
    init(divisions: [THDivision], holes: [THHole]) {
        self._initFinished = State(initialValue: true)
        self._divisions = State(initialValue: divisions)
        self.holes = holes
    }
    
    func loadDivisions() async {
        do {
            divisions = try await NetworkRequests.shared.loadDivisions()
            initFinished = true
        } catch NetworkError.ignore {
            // cancelled, ignore
        } catch let error as NetworkError {
            initError = error.localizedErrorDescription
        } catch {
            initError = ErrorInfo(title: "Unknown Error",
                                  description: "Error description: \(error.localizedDescription)")
        }
    }
    
    var body: some View {
        LoadingView(loading: $loading,
                        finished: $initFinished,
                        errorDescription: initError.description,
                        action: loadDivisions) {
            DelegatePage(searchText: $searchText,
                         searchSubmitted: $searchSubmitted,
                         divisions: divisions,
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
    let divisions: [THDivision]
    let holes: [THHole]
    
    var body: some View {
        Group {
            if isSearching {
                SearchPage(searchText: $searchText,
                           searchSubmitted: $searchSubmitted)
            } else {
                BrowsePage(divisions: divisions, holes: holes)
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
