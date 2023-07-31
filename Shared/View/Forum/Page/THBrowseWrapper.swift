import SwiftUI

struct THBrowseWrapper: View {
    @StateObject private var browseModel = THBrowseModel()
    @StateObject private var searchModel = THSearchModel()
    
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
    @EnvironmentObject private var model: THSearchModel
    @Environment(\.isSearching) private var isSearching
    
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
