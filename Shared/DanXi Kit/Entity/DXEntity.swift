import Foundation

struct DXUser: Hashable, Codable, Identifiable {
    let id: Int
    let nickname: String
    let joinTime: Date
    let isAdmin: Bool
}

struct Token: Codable {
    let access: String
    let refresh: String
}
