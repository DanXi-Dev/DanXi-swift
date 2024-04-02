import Foundation

/// App-wide cache store for electricity usage. Invalidated between app launches.
public actor ElectricityStore {
    public static let shared = ElectricityStore()
    
    var usage: ElectricityUsage? = nil
    
    /// Get cached electricity usage
    public func getCachedElectricityUsage() async throws -> ElectricityUsage {
        if let usage = usage {
            return usage
        }
        
        return try await getRefreshedEletricityUsage()
    }
    
    /// Refresh cache and get new electricity usage from server
    public func getRefreshedEletricityUsage() async throws -> ElectricityUsage {
        let usage = try await ElectricityAPI.getElectricityUsage()
        self.usage = usage
        return usage
    }
}
