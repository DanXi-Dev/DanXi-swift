import Foundation

public actor MyStore {
    public static let shared = MyStore()
    
    let dataValidFor: TimeInterval = 1 * 60 * 60
    public var lastUpdated = Date.distantPast
    public var outdated: Bool {
        lastUpdated + dataValidFor < Date.now
    }
    
    public func clearCache() {
        electricityLog = nil
    }
    
    var electricityLog: [ElectricityLog]? = nil
    
    public func getCachedElectricityLogs() async throws -> [ElectricityLog] {
        if let electricityLog = electricityLog {
            return electricityLog
        }
        
        return try await getRefreshedElectricityLogs()
    }
    
    public func getRefreshedElectricityLogs() async throws -> [ElectricityLog] {
        let electricityLog = try await MyAPI.getElectricityLogs()
        self.electricityLog = electricityLog
        self.lastUpdated = Date.now
        return electricityLog
    }
    
    public func setupPreivew(electricity: [ElectricityLog]) {
        electricityLog = electricity
    }
}
