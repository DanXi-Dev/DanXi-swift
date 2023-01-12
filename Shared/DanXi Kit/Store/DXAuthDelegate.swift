import Foundation

class DXAuthDelegate: ObservableObject {
    static var shared = DXAuthDelegate()
    
    @Published var isLogged: Bool
    
    init() {
        self.isLogged = DXSecStore.shared.token != nil
    }
    
    func refreshToken() async throws {
        let token = try await DXAuthRequests.refreshToken()
        DXSecStore.shared.update(token)
    }
    
    func login(username: String, password: String) async throws {
        let token = try await DXAuthRequests.login(username: username, password: password)
        DXSecStore.shared.store(token)
        try await DXUserStore.shared.updateUser()
        Task { @MainActor in
            isLogged = true
        }
    }
    
    func logout() {
        Task {
            do {
                try await DXAuthRequests.logout()
            }
        }
        
        DXSecStore.shared.delete()
        isLogged = false
        
        DXUserStore.shared.clear()
        THStore.shared.clear()
        DKStore.shared.clear()
    }
    
    func register(email: String, password: String, verification: String, create: Bool) async throws {
        let token = try await DXAuthRequests.register(email: email, password: password, verification: verification, create: create)
        DXSecStore.shared.store(token)
        isLogged = true
    }
    
    func resetPassword(email: String, password: String, verification: String) async throws {
        let token = try await DXAuthRequests.register(email: email, password: password, verification: verification, create: false)
        DXSecStore.shared.store(token)
        isLogged = true
    }
}
