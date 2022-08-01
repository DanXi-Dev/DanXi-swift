import Foundation

var treeholeDataModel = TreeholeDataModel()

class TreeholeDataModel: ObservableObject {
    @Published var divisions: [THDivision] = []
    @Published var tags: [THTag] = []
    @Published var user: THUser?
    @Published var loggedIn: Bool = false
    
    init() {
        let defaults = UserDefaults(suiteName: "group.io.github.kavinzhao.fdutools")
        guard defaults?.string(forKey: "user-credential") != nil else {
            return
        }
        
        loggedIn = true
        initialFetch()
    }
    
    func initialFetch() {
        Task { @MainActor in
            do {
                async let tags = networks.loadTags()
                async let user = networks.loadUserInfo()
                
                self.tags = try await tags
                self.user = try await user
            } catch {
                print("DANXI-DEBUG: initial load failed")
            }
        }
    }
    
    func updateBookmarks(bookmarks: [Int]) {
        Task { @MainActor in
            user?.favorites = bookmarks
        }
    }
}
