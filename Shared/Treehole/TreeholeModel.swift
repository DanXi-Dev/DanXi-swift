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
                self.tags = try await networks.loadTags() // FIXME: publish on main thread
            } catch {
                print("DANXI-DEBUG: initial load failed")
            }
        }
    }
}
