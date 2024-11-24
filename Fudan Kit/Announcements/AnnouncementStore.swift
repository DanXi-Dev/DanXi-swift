import Foundation

/// App-wide cache for announcement. Cache is invalidated between app launches.
public actor UndergraduateAnnouncementStore {
    public static let shared = UndergraduateAnnouncementStore()
    
    var page = 1
    var finished = false
    var announcements: [Announcement] = []
    let dataValidFor: TimeInterval = 1 * 60 * 60
    public var lastUpdated = Date.distantPast
    public var outdated: Bool {
        lastUpdated + dataValidFor < Date.now
    }
    
    public func clearCache() {
        announcements = []
        page = 1
        finished = false
    }
    
    /// Fetch more announcements and return the entire list
    public func getCachedAnnouncements() async throws -> [Announcement] {
        if finished { return self.announcements }
        
        let announcementDelta = try await AnnouncementAPI.getUndergraduateAnnouncement(page: page)
        page += 1
        self.announcements += announcementDelta
        finished = announcementDelta.isEmpty
        return self.announcements
    }
    
    /// Clear cache and load annoucements from server
    public func getRefreshedAnnouncements() async throws -> [Announcement] {
        page = 1
        finished = false
        self.announcements = try await AnnouncementAPI.getUndergraduateAnnouncement(page: page)
        finished = self.announcements.isEmpty
        self.lastUpdated = Date.now
        return self.announcements
    }
}

public actor PostgraduateAnnouncementStore {
    public static let shared = PostgraduateAnnouncementStore()
    
    var page = 1
    var finished = false
    var announcements: [Announcement] = []
    let dataValidFor: TimeInterval = 1 * 60 * 60
    public var lastUpdated = Date.distantPast
    public var outdated: Bool {
        lastUpdated + dataValidFor < Date.now
    }
    
    public func clearCache() {
        announcements = []
        page = 1
        finished = false
    }
    
    /// Fetch more announcements and return the entire list
    public func getCachedAnnouncements() async throws -> [Announcement] {
        if finished { return self.announcements }
        
        let announcementDelta = try await AnnouncementAPI.getPostgraduateAnnouncement(page: page)
        page += 1
        self.announcements += announcementDelta
        finished = announcementDelta.isEmpty
        return self.announcements
    }
    
    /// Clear cache and load annoucements from server
    public func getRefreshedAnnouncements() async throws -> [Announcement] {
        page = 1
        finished = false
        self.announcements = try await AnnouncementAPI.getPostgraduateAnnouncement(page: page)
        finished = self.announcements.isEmpty
        self.lastUpdated = Date.now
        return self.announcements
    }
}
