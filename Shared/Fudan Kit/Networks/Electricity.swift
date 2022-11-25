import Foundation

struct ElectricityRequest {
    static func getDormInfo() async throws -> DormInfo {
        let url = URL(string: "https://zlapp.fudan.edu.cn/fudanelec/wap/default/info")!
        let responseData = try await FudanAuthRequests.auth(url: url)
        return try JSONDecoder().decode(DormInfo.self, from: responseData)
    }
}

struct DormInfo: Decodable {
    
    let campus: String
    let building: String
    let roomNo: String
    
    let updateTime: String
    let usedElectricity: Float
    let availableElectricity: Float
    let allElectricity: Float
    
    enum CodingKeys: String, CodingKey {
        case data = "d"
        enum DataKeys: String, CodingKey {
            case campus = "xq"
            case building = "ssmc"
            case roomNo = "fjmc"
            case updateTime = "fj_update_time"
            case usedElectricity = "fj_used"
            case availableElectricity = "fj_surplus"
            case allElectricity = "fj_all"
        }
    }
    
    init(from decoder: Decoder) throws {
        let data = try decoder.container(keyedBy: CodingKeys.self)
        let values = try data.nestedContainer(keyedBy: CodingKeys.DataKeys.self, forKey: .data)
        campus = try values.decode(String.self, forKey: .campus)
        building = try values.decode(String.self, forKey: .building)
        roomNo = try values.decode(String.self, forKey: .roomNo)
        updateTime = try values.decode(String.self, forKey: .updateTime)
        usedElectricity = try values.decode(Float.self, forKey: .usedElectricity)
        availableElectricity = try values.decode(Float.self, forKey: .availableElectricity)
        allElectricity = try values.decode(Float.self, forKey: .allElectricity)
    }
}
