import Foundation

class FudanAuthDelegate: ObservableObject {
    static var shared = FudanAuthDelegate()
    
    @Published var isLogged: Bool
    
    init() {
        self.isLogged = CredentialStore.shared.username != nil
                        && CredentialStore.shared.password != nil
    }
    
    func login(_ username: String, _ password: String) async throws {
        try await FudanAuthRequests.login(username, password)
        
        CredentialStore.shared.store(username, password)
        Task { @MainActor in
            isLogged = true
        }
    }
    
    func logout() {
        CredentialStore.shared.delete()
        isLogged = false
    }
}
