import SwiftUI
import ViewUtils
import Utils
import DanXiKit

struct ForumHomePage: View {
    func loadAll() async throws {
        if !DivisionStore.shared.initialized {
            try await DivisionStore.shared.refreshDivisions()
        }
        
        if !FavoriteStore.shared.initialized {
            try await FavoriteStore.shared.refreshFavoriteIds()
        }
        
        if !ProfileStore.shared.initialized {
            try await ProfileStore.shared.refreshProfile()
        }
        
        if !SubscriptionStore.shared.initialized {
            try await SubscriptionStore.shared.refreshSubscriptionIds()
        }
        
        if !TagStore.shared.initialized {
            try await TagStore.shared.refreshTags()
        }
    }
    
    var body: some View {
        AsyncContentView {
            try await loadAll()
            guard let division = DivisionStore.shared.divisions.first else {
                let description = String(localized: "Division list is empty", bundle: .module)
                throw LocatableError(description)
            }
            let model = BrowseModel(division: division)
            return model
        } content: { model in
            BrowseWrpper(model)
        }
        .navigationTitle(String(localized: "Forum", bundle: .module))
    }
}

private struct BrowseWrpper: View {
    @StateObject private var browseModel: BrowseModel
    @StateObject private var searchModel = SearchModel()
    
    init(_ browseModel: BrowseModel) {
        self._browseModel = StateObject(wrappedValue: browseModel)
    }
    
    var body: some View {
        BrowseDispatch()
            .searchable(text: $searchModel.searchText)
            .searchScopes($searchModel.scope) {
                Text("Fuzzy", bundle: .module).tag(SearchScope.fuzzy)
                Text("Accurate", bundle: .module).tag(SearchScope.accurate)
            }
            .onSubmit(of: .search) {
                searchModel.submitted = true
                searchModel.appendHistory(searchModel.searchText)
            }
            .environmentObject(browseModel)
            .environmentObject(searchModel)
    }
}

private struct BrowseDispatch: View {
    @Environment(\.isSearching) private var isSearching
    @EnvironmentObject private var model: SearchModel
    
    var body: some View {
        if isSearching {
            if model.submitted {
                SearchResultPage()
            } else {
                SearchPage()
            }
        } else {
            BrowsePage()
        }
    }
}
