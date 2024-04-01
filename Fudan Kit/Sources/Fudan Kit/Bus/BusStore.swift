
/// App-wide cache for bus schedule. The cache is invalidated between app launches.
public actor BusStore {
    public static let shared = BusStore()
    
    var workdayRoutes: [Route]? = nil
    var holidayRoutes: [Route]? = nil
    
    
    /// Get bus routes. It may reuse cached results.
    /// - Returns: A tuple of `(workdayRoutes, holidayRoutes)`
    public func getCachedRoutes() async throws -> ([Route], [Route]) {
        if let workdayRoutes = workdayRoutes, let holidayRoutes = holidayRoutes {
            return (workdayRoutes, holidayRoutes)
        }
        
        return try await getRefreshedRoutes()
    }
    
    
    /// Invalidate cache and reload routes from server.
    /// - Returns: A tuple of `(workdayRoutes, holidayRoutes)`
    public func getRefreshedRoutes() async throws -> ([Route], [Route]) {
        let (workdayRoutes, holidayRoutes) = try await (BusAPI.getRoutes(type: .workday), BusAPI.getRoutes(type: .holiday))
        self.workdayRoutes = workdayRoutes
        self.holidayRoutes = holidayRoutes
        return (workdayRoutes, holidayRoutes)
    }
}
