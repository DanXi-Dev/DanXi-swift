import Foundation

class FDAuthDelegate: ObservableObject {
    static var shared = FDAuthDelegate()
    
    @Published var isLogged: Bool
    
    init() {
        self.isLogged = FDSecStore.shared.username != nil
                        && FDSecStore.shared.password != nil
    }
    
    func login(_ username: String, _ password: String) async throws {
        try await FudanAuthRequests.login(username, password)
        
        FDSecStore.shared.store(username, password)
        Task { @MainActor in
            isLogged = true
        }
    }
    
    func logout() {
        FDSecStore.shared.delete()
        isLogged = false
    }
}
