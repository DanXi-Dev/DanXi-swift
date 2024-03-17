import Foundation

/// An announcement by the academic office, aka 教务处通知
public struct Announcement: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let date: Date
    public let link: URL
}
