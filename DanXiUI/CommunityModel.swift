import SwiftUI
import DanXiKit

public class CommunityModel: ObservableObject {
    public static let shared = CommunityModel()
    
    @Published public var loggedIn: Bool
    
    public init() {
        loggedIn = (CredentialStore.shared.token != nil)
    }
    
    @MainActor
    private func setLogin(loggedIn: Bool) {
        self.loggedIn = loggedIn
    }
    
    public func login(email: String, password: String) async throws {
        let token = try await GeneralAPI.login(email: email, password: password)
        CredentialStore.shared.token = token
        await setLogin(loggedIn: true)
        NotificationManager.shared.uploadAPNSToken()
    }
    
    
    public func setToken(token: Token) async {
        CredentialStore.shared.token = token
        await setLogin(loggedIn: true)
        NotificationManager.shared.uploadAPNSToken()
    }
    
    public func logout() async {
        await setLogin(loggedIn: false)
        Task {
            // try? await GeneralAPI.logout()
            if let deviceId = await UIDevice.current.identifierForVendor?.uuidString {
                try? await ForumAPI.deleteNotificationToken(deviceId: deviceId)
            }
            CredentialStore.shared.token = nil
            await FavoriteStore.shared.clear()
            await HistoryStore.shared.clearHistory()
            await ProfileStore.shared.clear()
            await SubscriptionStore.shared.clear()
            await TagStore.shared.clear()
        }
    }
}
