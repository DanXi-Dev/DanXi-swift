import SwiftUI
import KeychainAccess

class FDModel: ObservableObject {
    // MARK: - General
    
    static var shared = FDModel()
    private init() {
        username = keychain["username"]
        password = keychain["password"]
        isLogged = (username != nil) && (password != nil)
    }
    
    func clearAll() {
        username = nil
        password = nil
        studentType = .undergrad
    }
    
    @AppStorage("fd-student-type") var studentType = FDStudentType.undergrad
    
    // MARK: - Authentication
    
    let keychain = Keychain(service: "com.fduhole.fdutools")
    @Published var isLogged: Bool = false
    var username: String? {
        didSet { keychain["username"] = username }
    }
    var password: String? {
        didSet { keychain["password"] = password }
    }
    
    
    func login(_ username: String, _ password: String) async throws {
        try await FDAuthAPI.login(username, password)
        self.username = username
        self.password = password
        Task { @MainActor in isLogged = true }
    }
    
    func logout() {
        isLogged = false
        clearAll()
    }
}

enum FDStudentType: Int {
    case undergrad = 0
    case grad
    case staff
}
