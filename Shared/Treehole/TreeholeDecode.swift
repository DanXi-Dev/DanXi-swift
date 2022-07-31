import Foundation
import SwiftUI

extension THFloor {
    enum CodingKeys: String, CodingKey {
        case id = "floor_id"
        case iso8601UpdateTime = "time_updated"
        case iso8601CreateTime = "time_created"
        case like
        case liked
        case isMe = "is_me"
        case deleted
        case holeId = "hole_id"
        case storey, content
        case posterName = "anonyname"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        like = try values.decode(Int.self, forKey: .like)
        liked = try values.decodeIfPresent(Bool.self, forKey: .liked)
        isMe = try values.decodeIfPresent(Bool.self, forKey: .isMe) ?? false
        deleted = try values.decodeIfPresent(Bool.self, forKey: .deleted) ?? false
        holeId = try values.decode(Int.self, forKey: .holeId)
        storey = try values.decode(Int.self, forKey: .storey)
        content = try values.decode(String.self, forKey: .content)
        posterName = try values.decode(String.self, forKey: .posterName)
        iso8601UpdateTime = try values.decode(String.self, forKey: .iso8601UpdateTime)
        iso8601CreateTime = try values.decode(String.self, forKey: .iso8601CreateTime)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withTimeZone,.withFractionalSeconds,.withInternetDateTime]
        if let ut = formatter.date(from: iso8601UpdateTime), let ct = formatter.date(from: iso8601CreateTime) {
            updateTime = ut
            createTime = ct
        } else {
            throw TreeholeError.invalidFormat(reason: "Invalid ISO8601 Date")
        }
    }
}

extension THUser {
    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case nickname
    }
}

extension THDivision {
    enum CodingKeys: String, CodingKey {
        case id = "division_id"
        case name
        case description
        case pinned
    }
}

extension THTag {
    enum CodingKeys: String, CodingKey {
        case id = "tag_id"
        case name, temperature
    }
    
    init(id: Int, temperature: Int, name: String) {
        self.id = id
        self.temperature = temperature
        self.name = name
        self.color = THTag.parseColor(name: name)
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        let nameStr = try values.decode(String.self, forKey: .name)
        name = nameStr
        temperature = try values.decode(Int.self, forKey: .temperature)
        
        color = THTag.parseColor(name: nameStr)
    }
    
    // TODO: add undefined colors
    static let colorList = [
        Color.red,
        Color.pink,
        Color.purple,
        Color.secondary, // deep-purple,
        Color.indigo,
        Color.blue,
        Color.secondary, // light-blue
        Color.cyan,
        Color.teal,
        Color.green,
        Color.secondary, // light-greem
        Color.secondary, // lime
        Color.yellow,
        Color.secondary, // amber
        Color.orange,
        Color.secondary, // deep-orange
        Color.brown,
        Color.secondary, // blue-grey
        Color.secondary // grey
    ]
    
    static func parseColor(name: String) -> Color {
        if name.starts(with: "*") { // folding tags
            return Color.red
        }
        
        var sum = 0
        for c in name.utf16 {
            sum += Int(c)
        }
        sum %= THTag.colorList.count
        return THTag.colorList[sum]
    }
}

extension THHole {
    enum CodingKeys: String, CodingKey {
        case id = "hole_id"
        case divisionId = "division_id"
        case view
        case reply
        case iso8601UpdateTime = "time_updated"
        case iso8601CreateTime = "time_created"
        case tags
        
        case floorStruct = "floors"
        enum FloorsKeys: String, CodingKey {
            case firstFloor = "first_floor"
            case lastFloor = "last_floor"
            case floors = "prefetch"
        }
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        divisionId = try values.decode(Int.self, forKey: .divisionId)
        view = try values.decode(Int.self, forKey: .view)
        reply = try values.decode(Int.self, forKey: .reply)
        tags = try values.decode([THTag].self, forKey: .tags)
        iso8601UpdateTime = try values.decode(String.self, forKey: .iso8601UpdateTime)
        iso8601CreateTime = try values.decode(String.self, forKey: .iso8601CreateTime)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withTimeZone,.withFractionalSeconds,.withInternetDateTime]
        if let ut = formatter.date(from: iso8601UpdateTime), let ct = formatter.date(from: iso8601CreateTime) {
            updateTime = ut
            createTime = ct
        } else {
            throw TreeholeError.invalidFormat(reason: "Invalid ISO8601 Date")
        }
        
        let floorStruct = try values.nestedContainer(keyedBy: CodingKeys.FloorsKeys.self, forKey: .floorStruct)
        firstFloor = try floorStruct.decode(THFloor.self, forKey: .firstFloor)
        lastFloor = try floorStruct.decode(THFloor.self, forKey: .lastFloor)
        floors = try floorStruct.decode([THFloor].self, forKey: .floors)
    }
}
