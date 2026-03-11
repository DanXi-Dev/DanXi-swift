import SwiftUI

class ForumModel: ObservableObject {
    static let shared = ForumModel()
    
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
                try? await TagStore.shared.refreshTags() // Tags sometimes fail to load due to campus network issues, make it fail silently instead of crashing the whole page
            }
        }
        
        try await divisionTask.value
        try await favoriteTask.value
        try await profileTask.value
        try await subscriptionTask.value
        await tagTask.value
    }
}
