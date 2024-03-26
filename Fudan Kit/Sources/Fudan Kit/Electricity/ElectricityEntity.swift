import Foundation

public struct ElectricityUsage: Codable {
    public let campus: String
    public let building: String
    public let room: String
    
    public let updateTime: String
    public let electricityUsed: Float
    public let electricityAvailable: Float
    public let electricityAll: Float
    
    enum CodingKeys: String, CodingKey {
        case campus = "xq"
        case building = "ssmc"
        case room = "fjmc"
        case updateTime = "fj_update_time"
        case electricityUsed = "fj_used"
        case electricityAvailable = "fj_surplus"
        case electricityAll = "fj_all"
    }
    
    static public func convertEnergyToMeasuredString(_ value: Float) -> String {
        let energy = Measurement<UnitEnergy>(value: Double(value), unit: .kilowattHours)
        let style = Measurement<UnitEnergy>.FormatStyle(width: .abbreviated)
        return style.format(energy)
    }
}
