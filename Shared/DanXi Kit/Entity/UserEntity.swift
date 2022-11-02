import Foundation

struct DXUser: Hashable, Codable, Identifiable {
    let id: Int
    let nickname: String
    let joinTime: Date
    let isAdmin: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case nickname
        case joinTime = "joined_time"
        case isAdmin = "is_admin"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        nickname = try values.decode(String.self, forKey: .nickname)
        isAdmin = try values.decode(Bool.self, forKey: .isAdmin)
        self.joinTime = try decodeDate(values, key: .joinTime)
    }
}

/// JWT Token Structure.
struct Token: Codable {
    let access: String
    let refresh: String
}
