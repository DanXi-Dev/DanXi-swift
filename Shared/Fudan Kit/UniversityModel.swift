import Foundation

@MainActor
class UniversityModel: ObservableObject {
    static let shared = UniversityModel()
    
    @Published var loggedIn: Bool
    
    init() {
        let defaults = UserDefaults(suiteName: "group.io.github.kavinzhao.fdutools")
        loggedIn = defaults?.bool(forKey: "fdu-logged-in") ?? false
    }
    
    func login(_ username: String, _ password: String) async throws {
        try await FDNetworks.shared.login(username, password)
        loggedIn = true
    }
}
