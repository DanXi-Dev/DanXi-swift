import SwiftUI
import ViewUtils
import DanXiKit

struct ForumHomePage: View {
    func loadAll() async throws {
        let divisionTask = Task {
            if !DivisionStore.shared.initialized {
                try await DivisionStore.shared.refreshDivisions()
            }
        }
        
        let favoriteTask = Task {
            if !FavoriteStore.shared.initialized {
                try await FavoriteStore.shared.refreshFavoriteIds()
            }
        }
        
        let profileTask = Task {
            if !ProfileStore.shared.initialized {
                try await ProfileStore.shared.refreshProfile()
            }
        }
        
        let subscriptionTask = Task {
            if !SubscriptionStore.shared.initialized {
                try await SubscriptionStore.shared.refreshSubscriptionIds()
            }
        }
        
        let tagTask = Task {
            if !TagStore.shared.initialized {
                try await TagStore.shared.refreshTags()
            }
        }
        
        try await divisionTask.value
        try await favoriteTask.value
        try await profileTask.value
        try await subscriptionTask.value
        try await tagTask.value
    }
    
    var body: some View {
        AsyncContentView {
            try await loadAll()
            guard let division = DivisionStore.shared.divisions.first else {
                throw URLError(.badServerResponse)
            }
            let model = BrowseModel(division: division)
            return model
        } content: { model in
            BrowseWrpper(model)
        }
        .navigationTitle("Forum")
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
