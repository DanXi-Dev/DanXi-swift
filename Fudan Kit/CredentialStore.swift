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
    var studentType: StudentType {
        didSet { keychain["campus-student-type"] = String(studentType.rawValue) }
    }
    
    public var credentialPresent: Bool {
        username != nil && password != nil
    }
    
    init() {
        let keychain = Keychain(service: "com.fduhole.fdutools", accessGroup: "group.com.fduhole.danxi")
        self.keychain = keychain
        self.username = keychain["username"]
        self.password = keychain["password"]
        
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
    
    func set(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    func unset() {
        self.username = nil
        self.password = nil
    }
    
    
}
