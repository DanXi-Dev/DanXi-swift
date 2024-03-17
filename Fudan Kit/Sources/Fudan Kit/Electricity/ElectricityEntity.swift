import Foundation

public struct ElectricityUsage {
    public let campus: String
    public let building: String
    public let room: String
    
    public let updateTime: String
    public let electricityUsed: String
    public let electricityAvailable: String
    public let electricityAll: String
}

extension ElectricityUsage: Codable {
    enum CodingKeys: String, CodingKey {
        case campus = "xq"
        case building = "ssmc"
        case room = "fjmc"
        case updateTime = "fj_update_time"
        case electricityUsed = "fj_used"
        case electricityAvailable = "fj_surplus"
        case electricityAll = "fj_all"
    }
}
