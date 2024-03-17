import SwiftUI

@MainActor
public class CampusModel: ObservableObject {
    @AppStorage("fd-student-type") public var studentType = StudentType.undergrad
    public var loggedIn: Bool {
        CredentialStore.shared.username != nil
    }
    
    public init() {
        
    }
    
    public func login(username: String, password: String) async throws {
        guard try await AuthenticationAPI.checkUserCredential(username: username, password: password) else {
            throw CampusError.loginFailed
        }
        
        CredentialStore.shared.set(username: username, password: password)
    }
    
    /// Bypass correctness check, only store the credential.
    ///
    /// - Warning:
    /// This may lead to following API calls to fail.
    public func forceLogin(username: String, password: String) {
        CredentialStore.shared.set(username: username, password: password)
    }
    
    public func logout() {
        CredentialStore.shared.unset()
        
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
