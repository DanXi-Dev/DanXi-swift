import Foundation
import KeychainAccess

public class CredentialStore {
    public static let shared = CredentialStore()
    
    let keychain: Keychain
    public var token: Token? {
        didSet {
            if let token {
                keychain[data: "token"] = try! JSONEncoder().encode(token)
            } else {
                keychain[data: "token"] = nil
            }
        }
    }
    
    init() {
        let keychain = Keychain(service: "com.fduhole.danxi")
        self.keychain = keychain
        
        if let data = keychain[data: "token"],
           let token = try? JSONDecoder().decode(Token.self, from: data) {
            self.token = token
        } else {
            self.token = nil
        }
    }
}

public struct Token: Codable {
    public let access: String
    let refresh: String
    
    public init(access: String, refresh: String) {
        self.access = access
        self.refresh = refresh
    }
}
