import Foundation

/// App-wide cache store for electricity usage. Invalidated between app launches.
public actor ElectricityStore {
    public static let shared = ElectricityStore()
    
    var usage: ElectricityUsage? = nil
    var lastUpdated = Date.distantPast
    let dataValidFor: TimeInterval = 1 * 60 * 60
    
    public func clearCache(onlyIfOutdated: Bool = false) {
        if onlyIfOutdated && lastUpdated + dataValidFor > Date.now {
            return
        }
        usage = nil
    }
    
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
        self.lastUpdated = Date.now
        return usage
    }
    
    public func setupPreview(usage: ElectricityUsage) {
        self.usage = usage
    }
}
