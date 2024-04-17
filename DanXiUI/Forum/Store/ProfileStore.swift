import SwiftUI
import Disk
import DanXiKit

class ProfileStore: ObservableObject {
    static let shared = ProfileStore()
    
    @Published var profile: Profile? = nil
    
    @MainActor
    private func set(profile: Profile?) {
        self.profile = profile
    }
    
    func refreshProfile() async throws {
        let profile = try await ForumAPI.getProfile()
        await set(profile: profile)
    }
    
    func clear() async {
        await set(profile: nil)
    }
}
