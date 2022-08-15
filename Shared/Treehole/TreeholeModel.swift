import Foundation
import UserNotifications

class TreeholeDataModel: ObservableObject {
    static let shared = TreeholeDataModel()
    
    @Published var divisions: [THDivision] = []
    @Published var tags: [THTag] = []
    @Published var user: THUser?
    @Published var loggedIn: Bool = false
    
    // Settings
    @Published var nlModelDebuggingMode: Bool = false
    
    init() {
        let defaults = UserDefaults(suiteName: "group.io.github.kavinzhao.fdutools")
        guard defaults?.string(forKey: "user-credential") != nil else {
            return
        }
        
        loggedIn = true
        initialFetch()
        
        // Request Notification Permission After Log In
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound],
            completionHandler: {_, _ in })
    }
    
    func initialFetch() {
        Task { @MainActor in
            do {
                async let tags = NetworkRequests.shared.loadTags()
                async let user = NetworkRequests.shared.loadUserInfo()
                
                self.tags = try await tags
                self.user = try await user
            } catch {
                print("DANXI-DEBUG: initial load failed")
            }
        }
    }
    
    func updateFavorites(favorites: [Int]) {
        Task { @MainActor in
            user?.favorites = favorites
        }
    }
}
