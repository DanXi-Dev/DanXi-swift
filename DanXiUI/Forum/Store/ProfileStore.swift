import SwiftUI
import Disk
import DanXiKit

class ProfileStore: ObservableObject {
    static let shared = ProfileStore()
    
    @Published var profile: Profile? = nil
    var initialized = false
    
    var isAdmin: Bool {
        if let profile {
            profile.isAdmin
        } else {
            false
        }
    }
    
    var answered: Bool {
        if let profile {
            profile.answeredQuestions
        } else {
            true
        }
    }
    
    @MainActor
    private func set(profile: Profile?) {
        self.profile = profile
    }
    
    func refreshProfile() async throws {
        let profile = try await ForumAPI.getProfile()
        await set(profile: profile)
        initialized = true
    }
    
    func clear() async {
        await set(profile: nil)
        initialized = false
    }
}
