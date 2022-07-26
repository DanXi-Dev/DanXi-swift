import Foundation


@MainActor
class THDataModel: ObservableObject {
    private let defaults = UserDefaults(suiteName: "group.io.github.kavinzhao.fdutools") // TODO: move to keychain
    
    // user info
    @Published var isLogged: Bool = false
    @Published var account: THUser?
    var token: String? {
        didSet {
            defaults?.setValue(token, forKey: "user_credential")
        }
    }
    
    // treehole info
    @Published var divisions: [THDivision] = []
    @Published var tags: [THTag] = []
    @Published var currentDivision = THDivision(id: 1, name: "树洞", description: "", pinned: []) // dummy value
    
    init() {
        if let token = defaults?.string(forKey: "user_credential") {
            self.token = token
            isLogged = true
            
            if divisions.isEmpty {
                initialFetch()
            }
        }
    }
    
    init(divisions: [THDivision]? = [], tags: [THTag]) { // for preview
        isLogged = true
        self.divisions = divisions ?? []
        if !self.divisions.isEmpty {
            self.currentDivision = self.divisions[0]
        }
        self.tags = tags
    }
    
    func login(username: String, password: String) async -> Bool {
        guard let token = await THlogin(username: username, password: password) else {
            print("DANXI-DEBUG: login fail")
            return false
        }
        
        self.token = token
        isLogged = true
        
        initialFetch()
        return true
    }
    
    func logout() {
        defaults?.removeObject(forKey: "user_credential")
        isLogged = false
        token = nil
    }
    
    func initialFetch() {
        Task {
            guard let token = self.token else {
                return
            }
            
            do {
                async let divisions = try await THloadDivisions(token: token)
                async let tags = try await THloadTags(token: token)
                
                self.divisions = try await divisions
                if !self.divisions.isEmpty {
                    currentDivision = self.divisions[0]
                }
                self.tags = try await tags
            } catch {
                print("DANXI-DEBUG: initial fetch failed")
            }
        }
    }
    
    func fetchDivisions() async {
        guard let token = self.token else {
            return
        }
        
        do {
            divisions = try await THloadDivisions(token: token)
        } catch {
            print("DANXI-DEBUG: load divisions failed")
        }
    }
}
