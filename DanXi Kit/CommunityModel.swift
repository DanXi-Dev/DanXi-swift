import SwiftUI

public class CommunityModel: ObservableObject {
    public static let shared = CommunityModel()
    
    @Published public var loggedIn: Bool
    
    public init() {
        loggedIn = (CredentialStore.shared.token != nil)
    }
    
    @MainActor
    private func setLogin(loggedIn: Bool) {
        self.loggedIn = loggedIn
    }
    
    public func login(email: String, password: String) async throws {
        let token = try await GeneralAPI.login(email: email, password: password)
        CredentialStore.shared.token = token
        await setLogin(loggedIn: true)
    }
    
    
    public func setToken(token: Token) async {
        CredentialStore.shared.token = token
        await setLogin(loggedIn: true)
    }
    
    
    public func logout() async {
        CredentialStore.shared.token = nil
        await setLogin(loggedIn: false)
        Task {
            try await GeneralAPI.logout()
        }
    }
}
