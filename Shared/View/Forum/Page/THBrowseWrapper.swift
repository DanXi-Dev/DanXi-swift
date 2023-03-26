import SwiftUI

struct THBrowseWrapper: View {
    @StateObject var browseModel = THBrowseModel()
    @StateObject var searchModel = THSearchModel()
    
    var body: some View {
        THBrowseDispatch()
            .searchable(text: $searchModel.searchText)
            .onSubmit(of: .search) {
                searchModel.submitted = true
                searchModel.appendHistory(searchModel.searchText)
            }
            .environmentObject(browseModel)
            .environmentObject(searchModel)
    }
}

struct THBrowseDispatch: View {
    @EnvironmentObject var model: THSearchModel
    @Environment(\.isSearching) var isSearching
    
    var body: some View {
        Group {
            if isSearching {
                if model.submitted {
                    THSearchResultPage()
                } else {
                    THSearchPage()
                }
            } else {
                THBrowsePage()
            }
        }
    }
}
