import Foundation

/// App-wide cache for wallet-related functions. Cache is invalidated between app launches.
public actor WalletStore {
    public static let shared = WalletStore()
    
    var content: WalletContent? = nil
    
    public func clearCache() {
        content = nil
    }
    
    public func getCachedContent() async throws -> WalletContent {
        if let content {
            return content
        }
        
        return try await getRefreshedContent()
    }
    
    public func getRefreshedContent() async throws -> WalletContent {
        let content = try await WalletAPI.getContent()
        self.content = content
        return content
    }
}
