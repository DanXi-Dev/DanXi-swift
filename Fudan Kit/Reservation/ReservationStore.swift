import Foundation
import Disk

/// App-wide cache for reservation. Cache is persisted to disk.
/// Only `Playground` is cached, not `Reservation`, which
/// should be queried on-demand.
public actor ReservationStore {
    public static let shared = ReservationStore()
    
    var playgrounds: [Playground]?
    var logged = false
    
    init() {
        playgrounds = try? Disk.retrieve("fdutools/playgrounds.json", from: .applicationSupport, as: [Playground].self)
    }
    
    /// Get cached playgrounds
    public func getCachedPlayground() async throws -> [Playground] {
        if let playgrounds = playgrounds {
            return playgrounds
        }
        
        return try await getRefreshedPlayground()
    }
    
    
    /// Invalidate cache and return new data froms erver
    public func getRefreshedPlayground() async throws -> [Playground] {
        if !logged {
            try await ReservationAPI.login()
            logged = true
        }
        
        let playgrounds = try await ReservationAPI.getPlaygrounds()
        self.playgrounds = playgrounds
        try Disk.save(playgrounds, to: .applicationSupport, as: "fdutools/playgrounds.json")
        return playgrounds
    }
    
    public func getReservations(playground: Playground, date: Date) async throws -> [Reservation] {
        if !logged {
            try await ReservationAPI.login()
            logged = true
        }
        
        return try await ReservationAPI.getReservations(playground: playground, date: date)
    }
}
