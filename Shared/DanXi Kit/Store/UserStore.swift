import Foundation

class UserStore: ObservableObject {
    static var shared = UserStore()
    
    @Published var user: DXUser?
    var updated = false
    
    var isAdmin: Bool {
        if let user = user {
            return user.isAdmin
        } else {
            return false
        }
    }
    
    init() {
        do {
            user = try loadData(filename: "dx-user.data")
        } catch {
            user = nil
        }
    }
    
    func updateUser() async throws {
        if updated { return }
        
        let user = try await AuthReqest.loadUserInfo()
        try saveData(user, filename: "dx-user.data")
        updated = true
        
        Task { @MainActor in
            self.user = user
        }
    }
    
    func clear() {
        do {
            self.user = nil
            try removeData(filename: "dx-user.data")
        } catch { }
    }
}
