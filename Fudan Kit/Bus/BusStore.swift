#if !os(watchOS)
import Disk
#endif
import Utils

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
    
    /// Get bus routes if it is cached on disk
    /// Return nil otherwise
    /// This is supposed to be used by widgets
    public func getDiskCachedRoutes() -> ([Route], [Route])? {
        if let routes = try? Disk.retrieve("fdutools/bus.json", from: .appGroup, as: BusRoutes.self) {
            return (routes.workday, routes.weekend)
        }
        return nil
    }
    
    /// Invalidate cache and reload routes from server.
    /// - Returns: A tuple of `(workdayRoutes, holidayRoutes)`
    public func getRefreshedRoutes() async throws -> ([Route], [Route]) {
        let (workdayRoutes, holidayRoutes) = try await (BusAPI.getRoutes(type: .workday), BusAPI.getRoutes(type: .holiday))
        self.workdayRoutes = workdayRoutes
        self.holidayRoutes = holidayRoutes
        
        // Save to disk for widget
        let routes = BusRoutes(workday: workdayRoutes, weekend: holidayRoutes)
        try Disk.save(routes, to: .appGroup, as: "fdutools/bus.json")
        
        return (workdayRoutes, holidayRoutes)
    }
    
    public func setupPreview(routes: BusRoutes) {
        self.holidayRoutes = routes.weekend
        self.workdayRoutes = routes.workday
    }
}
