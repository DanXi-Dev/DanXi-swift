import Foundation
import SwiftyJSON

/// API collection to get number of people in each library.
///
/// This API returns real-time data and should not be cached.
///
/// The API is discovered from 微信公众号 - 复旦大学图书馆微服务 - 微主页.
/// It is publicly available, no authorization is needed.
///
/// The API returns a JSON data. Here's an example:
/// ```json
/// {
///     "msg": "SUCCESS",
///     "code": "1",
///     "data": [
///       {
///         "campusId": "1",
///         "campusName": "文科馆",
///         "campusShortName": "文科馆",
///         "canInNumb": "708",
///         "distance": null,
///         "inNum": "492",
///         "libraryDesc": "",
///         "libraryNotice": "<p>开放时间8:00-22:00</p>",
///         "libraryOpenTime": "8:00~22:00",
///         "placeNum": "647",
///         "rotationInfoList": [
///           {
///             "bannerDesc": "",
///             "bannerFileId": "1745343306260262914",
///             "bannerFileUrl": "https:///mlibrary.fudan.edu.cn/oss/safecampus2/public/20240111/6f87cf19dd76402ab2e34ef2b2d1494d2em7pccct2.png",
///             "bannerIndex": "1",
///             "bannerName": "",
///             "id": 80,
///             "jumpAddress": "https:///mlibrary.fudan.edu.cn/reporth5/",
///             "libraryId": 1
///           }
///         ]
///       },
///       ...
///     ]
/// }
/// ```
public enum LibraryAPI {
    
    public static func getLibrary() async throws -> [Library] {
        let libraryURL = URL(string: "https://mlibrary.fudan.edu.cn/api/common/h5/getspaceseat")!
        let request = constructRequest(libraryURL, method: "POST")
        let (data, _) = try await URLSession.campusSession.data(for: request)
        
        // check if server returns an error
        let json = JSON(data)
        let code = json["code"].stringValue
        if code != "1" {
            throw CampusError.customError(message: json["msg"].stringValue)
        }
        
        // decode data and transform
        let libraryData = try JSON(data)["data"].rawData()
        let decodedResponse = try JSONDecoder().decode([LibraryResponse].self, from: libraryData)
        var libraries: [Library] = []
        for response in decodedResponse {
            guard let id = Int(response.campusId),
                  let current = Int(response.inNum),
                  let remaining = Int(response.canInNumb) else { continue }
            let name = response.campusName
            let capacity = current + remaining
            let openTime = response.libraryOpenTime
            let library = Library(id: id, name: name, current: current, capacity: capacity, openTime: openTime)
            libraries.append(library)
        }
        return libraries
    }
    
    private struct LibraryResponse: Codable {
        let campusId: String
        let campusName: String
        let inNum, canInNumb: String
        let libraryOpenTime: String
    }
}
