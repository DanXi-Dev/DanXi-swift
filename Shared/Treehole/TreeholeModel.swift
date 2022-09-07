import Foundation
import UserNotifications

class TreeholeDataModel: ObservableObject {
    static let shared = TreeholeDataModel()
    
    @Published var initialized = false
    @Published var divisions: [THDivision] = []
    @Published var tags: [THTag] = []
    @Published var user: THUser?
    @Published var loggedIn: Bool = false
    
    var isAdmin: Bool {
        user?.isAdmin ?? false
    }
    
    // Settings
    // TODO: save to user defaults
    @Published var nlModelDebuggingMode: Bool = false
    @Published var nsfwPreference = NSFWPreference.hide
    
    init() {
        let defaults = UserDefaults(suiteName: "group.io.github.kavinzhao.fdutools")
        guard defaults?.data(forKey: "user-credential") != nil else {
            return
        }
        
        loggedIn = true
        
        // Request Notification Permission After Log In
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound],
            completionHandler: {_, _ in })
    }
    
    @MainActor
    func fetchInfo() async throws {
        if initialized {
            return
        }
        
        async let tags = NetworkRequests.shared.loadTags()
        async let user = NetworkRequests.shared.loadUserInfo()
        async let divisions =  NetworkRequests.shared.loadDivisions()
        
        self.tags = try await tags
        self.user = try await user
        self.divisions = try await divisions
    }
    
    func updateFavorites(favorites: [Int]) {
        Task { @MainActor in
            user?.favorites = favorites
        }
    }
    
    func removeFavorate(_ holeId: Int) {
        if self.user != nil {
            self.user!.favorites = self.user!.favorites.filter { $0 != holeId }
        }
    }
}

enum NSFWPreference: Hashable {
    case show
    case hide
    case fold
}
