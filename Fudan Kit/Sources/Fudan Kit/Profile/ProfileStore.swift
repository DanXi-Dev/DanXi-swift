import Foundation
import Disk

/// App-wide cache for reservation. Cache is persisted to disk.
///
/// The cache should be cleared when user log out.
public actor ProfileStore {
    public static let shared = ProfileStore()
    
    var profile: Profile?
    
    init() {
        if let profile = try? Disk.retrieve("fdutools/profile.json", from: .applicationSupport, as: Profile.self) {
            self.profile = profile
            return
        }
        
        self.profile = nil
    }
    
    /// Get cached profile
    public func getCachedProfile() async throws -> Profile {
        if let profile = self.profile {
            return profile
        }
        
        let profile = try await ProfileAPI.getStudentProfile()
        self.profile = profile
        try Disk.save(profile, to: .applicationSupport, as: "fdutools/profile.json")
        return profile
    }
    
    /// Invalidate cache and return new data froms erver
    public func getRefreshedProfile() async throws -> Profile {
        profile = nil
        try Disk.remove("fdutools/profile.json", from: .applicationSupport)
        
        let profile = try await ProfileAPI.getStudentProfile()
        self.profile = profile
        try Disk.save(profile, to: .applicationSupport, as: "fdutools/profile.json")
        return profile
    }
    
    
    public func clearCache() throws {
        profile = nil
        try Disk.remove("fdutools/profile.json", from: .applicationSupport)
    }
}
