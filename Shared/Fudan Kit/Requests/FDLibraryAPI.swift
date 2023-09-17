import Foundation
import SwiftyJSON

struct FDLibraryAPI {
    static func getLibraries() async throws -> [FDLibrary] {
        let url = URL(string: "https://mlibrary.fudan.edu.cn/api/common/h5/getspaceseat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (data, _) = try await sendRequest(request)
        let libraryData = try JSON(data)["data"].rawData()
        return try processJSONData(libraryData)
    }
}

struct FDLibrary: Decodable, Identifiable {
    let id: Int
    let name: String
    let current: Int
    let capacity: Int
    let openTime: String
    
    enum CodingKeys: String, CodingKey {
        case id = "campusId"
        case name = "campusName"
        case current = "inNum"
        case remain = "canInNumb"
        case openTime = "libraryOpenTime"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let id = Int(try container.decode(String.self, forKey: .id)),
              let current = Int(try container.decode(String.self, forKey: .current)),
              let remain = Int(try container.decode(String.self, forKey: .remain)) else {
            throw ParseError.invalidJSON
        }
        self.id = id
        self.current = current
        self.capacity = current + remain
        self.name = try container.decode(String.self, forKey: .name)
        self.openTime = try container.decode(String.self, forKey: .openTime)
    }
}
