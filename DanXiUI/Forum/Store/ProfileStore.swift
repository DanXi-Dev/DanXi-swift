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
    
    func getRefreshedProfile() async throws -> Profile {
        let profile = try await ForumAPI.getProfile()
        await set(profile: profile)
        initialized = true
        return profile
    }
    
    func refreshProfile() async throws {
        let profile = try await ForumAPI.getProfile()
        await set(profile: profile)
        ForumSettings.shared.foldedContent =  switch profile.showFoldedConfiguration {
        case "fold": ForumSettings.SensitiveContentSetting.fold
        case "hide": ForumSettings.SensitiveContentSetting.hide
        case "show": ForumSettings.SensitiveContentSetting.show
        default: ForumSettings.SensitiveContentSetting.fold
        }
        initialized = true
    }
    
    func clear() async {
        await set(profile: nil)
        initialized = false
    }
}
