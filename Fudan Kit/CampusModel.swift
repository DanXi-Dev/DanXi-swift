import SwiftUI
#if os(watchOS)
import Utils
#else
import Disk
#endif

@MainActor
public class CampusModel: ObservableObject {
    
    public static let shared = CampusModel()
    
    @Published public var studentType: StudentType {
        didSet { CredentialStore.shared.studentType = studentType }
    }
    @Published public var loggedIn: Bool // cannot use computed property from credential store because it won't trigger SwiftUI reload
    
    public init() {
        studentType = CredentialStore.shared.studentType
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
        
        // remove all cookies
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        
        // clear cache
        Task(priority: .background) {
            // reset user defaults
            let defaults = UserDefaults.standard
            let dictionary = defaults.dictionaryRepresentation()
            dictionary.keys.forEach { key in
                if key.hasPrefix("fdutools") {
                    defaults.removeObject(forKey: key)
                }
            }
            
            // remove contents on disk
            try Disk.remove("fdutools", from: .appGroup)
        }
    }
}

public enum StudentType: Int, Codable {
    case undergrad = 0
    case grad
    case staff
}
