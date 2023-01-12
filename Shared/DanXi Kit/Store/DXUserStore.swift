import Foundation

class DXUserStore: ObservableObject {
    static var shared = DXUserStore()
    
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
        user = FileStore.caches.loadIfExsits("dx-user.data")
    }
    
    func updateUser() async throws {
        if updated { return }
        
        let user = try await DXAuthRequests.loadUserInfo()
        try FileStore.caches.saveEncoded(user, filename: "dx-user.data")
        updated = true
        
        Task { @MainActor in
            self.user = user
        }
    }
    
    func clear() {
        do {
            self.user = nil
            try FileStore.caches.remove("dx-user.data")
        } catch { }
    }
}
