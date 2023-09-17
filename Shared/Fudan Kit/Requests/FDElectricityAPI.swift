import Foundation

struct FDElectricityAPI {
    static func getDormInfo() async throws -> FDDormInfo {
        let url = URL(string: "https://zlapp.fudan.edu.cn/fudanelec/wap/default/info")!
        let data = try await FDAuthAPI.auth(url: url)
        let unwrapped = try unwrapJSON(data).rawData()
        return try processJSONData(unwrapped)
    }
}

struct FDDormInfo: Decodable {
    let campus: String
    let building: String
    let roomNo: String
    
    let updateTime: String
    let usedElectricity: Float
    let availableElectricity: Float
    let allElectricity: Float
    
    enum CodingKeys: String, CodingKey {
        case campus = "xq"
        case building = "ssmc"
        case roomNo = "fjmc"
        case updateTime = "fj_update_time"
        case usedElectricity = "fj_used"
        case availableElectricity = "fj_surplus"
        case allElectricity = "fj_all"
    }
}
