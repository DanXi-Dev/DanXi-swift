import SwiftUI

@MainActor
public class CampusModel: ObservableObject {
    
    public static let shared = CampusModel()
    
    @AppStorage("fd-student-type") public var studentType = StudentType.undergrad
    @Published public var loggedIn: Bool // cannot use computed property from credential store because it won't trigger SwiftUI reload
    
    public init() {
        if CredentialStore.shared.username != nil {
            loggedIn = true
        } else {
            loggedIn = false
        }
    }
    
    public func login(username: String, password: String) async throws {
        guard try await AuthenticationAPI.checkUserCredential(username: username, password: password) else {
            throw CampusError.loginFailed
        }
        
        CredentialStore.shared.set(username: username, password: password)
        loggedIn = true
    }
    
    /// Bypass correctness check, only store the credential.
    ///
    /// - Warning:
    /// This may lead to following API calls to fail.
    public func forceLogin(username: String, password: String) {
        CredentialStore.shared.set(username: username, password: password)
        loggedIn = true
    }
    
    public func logout() {
        CredentialStore.shared.unset()
        loggedIn = false
        
        // TODO: clear cookies
        
        // clear cache
        Task {
            try await ProfileStore.shared.clearCache()
        }
    }
}

public enum StudentType: Int {
    case undergrad = 0
    case grad
    case staff
}
