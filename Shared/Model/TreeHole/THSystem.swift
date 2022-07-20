import Foundation

class THSystem: ObservableObject {
    let defaults = UserDefaults(suiteName: "group.io.github.kavinzhao.fdutools") // TODO: move to keychain
    
    @Published var account: OTUser?
    @Published var isLogged: Bool = false
    var credential: String? {
        didSet {
            defaults?.setValue(credential, forKey: "user_credential")
        }
    }
}
