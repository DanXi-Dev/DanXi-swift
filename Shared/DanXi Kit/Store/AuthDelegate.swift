import Foundation

class AuthDelegate: ObservableObject {
    static var shared = AuthDelegate()
    
    @Published var isLogged: Bool
    
    init() {
        self.isLogged = SecStore.shared.token != nil
    }
    
    func refreshToken() async throws {
        let token = try await AuthReqest.refreshToken()
        SecStore.shared.update(token)
    }
    
    func login(username: String, password: String) async throws {
        let token = try await AuthReqest.login(username: username, password: password)
        SecStore.shared.store(token)
        try await UserStore.shared.updateUser()
        Task { @MainActor in
            isLogged = true
        }
    }
    
    func logout() {
        Task {
            do {
                try await AuthReqest.logout()
            }
        }
        
        SecStore.shared.delete()
        isLogged = false
        
        UserStore.shared.clear()
        TreeholeStore.shared.clear()
        CourseStore.shared.clear()
    }
    
    func register(email: String, password: String, verification: String, create: Bool) async throws {
        let token = try await AuthReqest.register(email: email, password: password, verification: verification, create: create)
        SecStore.shared.store(token)
        isLogged = true
    }
    
    func resetPassword(email: String, password: String, verification: String) async throws {
        let token = try await AuthReqest.register(email: email, password: password, verification: verification, create: false)
        SecStore.shared.store(token)
        isLogged = true
    }
}
