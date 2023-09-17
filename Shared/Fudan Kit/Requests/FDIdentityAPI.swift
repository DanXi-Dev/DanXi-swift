import Foundation
import SwiftyJSON

struct FDIdentityAPI {
    static func getIdentity() async throws -> FDIdentity {
        let url = URL(string: "https://workflow1.fudan.edu.cn/site/fudan/student-information")!
        let data = try await FDAuthAPI.auth(url: url)
        let json = try unwrapJSON(data)
        let content = try json["info"].rawData()
        return try JSONDecoder().decode(FDIdentity.self, from: content)
    }
}

struct FDIdentity: Codable {
    let studentId: String
    let name: String
    let gender: String
    let idNumber: String
    let department: String
    let major: String
    
    enum CodingKeys: String, CodingKey {
        case studentId = "XH"
        case name = "XM"
        case gender = "XB"
        case idNumber = "ZJHM"
        case department = "YX"
        case major = "ZY"
    }
}
