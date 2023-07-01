import Foundation

struct DXUser: Hashable, Codable, Identifiable {
    let id: Int
    let nickname: String
    let joinTime: Date
    let isAdmin: Bool
    var banned: Dictionary<Int, Date>
}

struct Token: Codable {
    let access: String
    let refresh: String
}

struct DXInfo: Codable {
    let id: String
    let content: String
    let type: Int
}

struct DXBanner: Codable {
    let title: String
    let actionName: String
    let action: String
}

struct Timetable: Codable {
    let semester: Int
    let startDate: Date
}
