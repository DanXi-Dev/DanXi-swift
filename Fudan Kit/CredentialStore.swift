import Foundation
import KeychainAccess

public class CredentialStore {
    public static let shared = CredentialStore()
    
    private let keychain: Keychain
    var username: String? {
        didSet { keychain["username"] = username }
    }
    var password: String? {
        didSet { keychain["password"] = password }
    }
    
    public var credentialPresent: Bool {
        username != nil && password != nil
    }
    
    init() {
        let keychain = Keychain(service: "com.fduhole.fdutools", accessGroup: "group.com.fduhole.danxi")
        self.keychain = keychain
        self.username = keychain["username"]
        self.password = keychain["password"]
    }
    
    func set(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    func unset() {
        self.username = nil
        self.password = nil
    }
    
    
}
