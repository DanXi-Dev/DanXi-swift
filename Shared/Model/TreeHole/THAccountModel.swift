import Foundation

class THAccountModel: ObservableObject {
    let defaults = UserDefaults(suiteName: "group.io.github.kavinzhao.fdutools") // TODO: move to keychain
    
    @Published var account: THUser?
    @Published var isLogged: Bool = false
    var credential: String? {
        didSet {
            defaults?.setValue(credential, forKey: "user_credential")
        }
    }
    
    init() {
        if let token = defaults?.string(forKey: "user_credential") {
            credential = token
            isLogged = true
        }
    }
    
    func logout() {
        defaults?.removeObject(forKey: "user_credential")
        credential = nil
        isLogged = false
    }
}
