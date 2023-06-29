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
