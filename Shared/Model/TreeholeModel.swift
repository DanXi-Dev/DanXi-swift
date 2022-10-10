import Foundation
import UserNotifications

@MainActor
class TreeholeDataModel: ObservableObject {
    static let shared = TreeholeDataModel()
    
    @Published var initialized = false
    @Published var divisions: [THDivision] = []
    @Published var tags: [THTag] = []
    @Published var user: DXUser?
    @Published var loggedIn: Bool = false
    var favorites: [Int] = []
    
    var isAdmin: Bool {
        user?.isAdmin ?? false
    }
    
    init() {
        let defaults = UserDefaults(suiteName: "group.io.github.kavinzhao.fdutools")
        guard defaults?.data(forKey: "user-credential") != nil else {
            return
        }
        
        loggedIn = true
        self.user = loadData(filename: "danxi-user.data")
        self.tags = loadData(filename: "treehole-tags.data") ?? []
        
        // Request Notification Permission After Log In
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound],
            completionHandler: {_, _ in })
    }
    
    func login(_ username: String, _ password: String) async throws {
        try await DXNetworks.shared.login(username: username, password: password)
        user = try await DXNetworks.shared.loadUserInfo()
        try saveData(user, filename: "danxi-user.data")
        loggedIn = true
    }
    
    func login() async throws {
        user = try await DXNetworks.shared.loadUserInfo()
        try saveData(user, filename: "danxi-user.data")
        loggedIn = true
    }
    
    func logout() {
        user = nil
        Task {
            try await DXNetworks.shared.logout()
        }
        loggedIn = false
        
        do {
            try saveData(user, filename: "danxi-user.data")
        } catch { }
    }
    
    // FIXME: load tag
    func fetchInfo() async throws {
        if initialized {
            return
        }
        
//        async let tags = DXNetworks.shared.loadTags()
        async let user = DXNetworks.shared.loadUserInfo()
        async let divisions = DXNetworks.shared.loadDivisions()
        async let favorites = DXNetworks.shared.loadFavoritesIds()
        
//        self.tags = try await tags
        self.user = try await user
        self.divisions = try await divisions
        self.favorites = try await favorites
        
        try saveData(await user, filename: "danxi-user.data")
//        try saveData(await tags, filename: "treehole-tags.data")
    }
    
    func toggleFavorite(_ holeId: Int, add: Bool) async throws {
        self.favorites = try await DXNetworks.shared.toggleFavorites(holeId: holeId, add: add)
    }
}
