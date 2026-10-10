import Foundation
import KeychainAccess

public struct Credential: Equatable {
    public let username: String
    public let password: String

    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

public class CredentialStore {
    public static let shared = CredentialStore()
    
    private let keychain: Keychain
    public var credential: Credential? = nil {
        didSet {
            keychain["username"] = credential?.username
            keychain["password"] = credential?.password
        }
    }

    /// Optional account for eCard requests.
    public private(set) var secondaryCredential: Credential? = nil

    public func setSecondaryCredential(_ credential: Credential?) {
        keychain["secondary-username"] = credential?.username
        keychain["secondary-password"] = credential?.password
        secondaryCredential = credential
    }

    public var studentType: StudentType {
        didSet { keychain["campus-student-type"] = String(studentType.rawValue) }
    }

    /// Select credentials using the original service URL, before any SSO redirect.
    public func credentials(for url: URL) -> Credential? {
        if url.host?.lowercased() == "ecard.fudan.edu.cn", let secondaryCredential {
            return secondaryCredential
        }
        return credential
    }
    
    init() {
        let keychain = Keychain(service: "com.fduhole.fdutools", accessGroup: "group.com.fduhole.danxi")
        self.keychain = keychain
        if let username = keychain["username"], let password = keychain["password"] {
            self.credential = Credential(username: username, password: password)
        }
        if let username = keychain["secondary-username"], let password = keychain["secondary-password"] {
            self.secondaryCredential = Credential(username: username, password: password)
        }
        
        // Migrate from old student type stored in UserDefaults
        let userDefaults = UserDefaults.standard
        if userDefaults.object(forKey: "campus-student-type") != nil {
            // Perform migration
            let oldStudentType = userDefaults.integer(forKey: "campus-student-type")
            self.studentType = StudentType(rawValue: oldStudentType) ?? .undergrad
            userDefaults.removeObject(forKey: "campus-student-type")
        } else { // No migration needed
            self.studentType = StudentType(rawValue: Int(keychain["campus-student-type"] ?? "0") ?? 0) ?? .undergrad
        }
    }
}
