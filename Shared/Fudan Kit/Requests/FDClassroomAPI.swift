import Foundation
import SwiftyJSON

// MARK: - Requests

struct FDClassroomAPI {
    static func getClassroomInfo(date: Date? = nil, campusCode: String? = nil, buildingCode: String? = nil) async throws -> FDClassroomInfo {
        var components = URLComponents(string: "https://zlapp.fudan.edu.cn/fudanzlfreeclass/wap/mobile/index")!
        var queryItems = [URLQueryItem(name: "pageSize", value: "10000")]
        if let date = date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            queryItems.append(URLQueryItem(name: "date", value: dateFormatter.string(from: date)))
        }
        if let campusCode = campusCode {
            queryItems.append(URLQueryItem(name: "xqdm", value: campusCode))
        }
        if let buildingCode = buildingCode {
            queryItems.append(URLQueryItem(name: "floor", value: buildingCode))
        }
        components.queryItems = queryItems

        let data = try await FDAuthAPI.auth(url: components.url!)
        return try FDClassroomInfo(data: data)
    }
}


// MARK: - Model

struct FDClassroomInfo {
    let classroomList: [FDClassroom]
    let buildingList: [FDBuilding]
    let campusList: [FDCampus]
    
    init(data: Data) throws {
        let json = try JSON(data: data)
        
        campusList = try JSONDecoder().decode([FDCampus].self,
                                              from: json["d", "area"].rawData())
        buildingList = try JSONDecoder().decode([FDBuilding].self,
                                                from: json["d", "floor"].rawData())
        
        // get the first element of a dictionary
        for (_, subJSON): (String, JSON) in json["d", "list"] {
            do {
                classroomList = try JSONDecoder().decode([FDClassroom].self, from: subJSON.rawData())
                return
            } catch {
                throw ParseError.invalidJSON
            }
        }
        
        throw ParseError.invalidResponse
    }
}

struct FDClassroom: Codable {
    let name: String
    let roomId: String
    let occupationStatus: [Int: String]
    
    enum CodingKeys: String, CodingKey {
        case name
        case roomId = "roomid"
        case occupationStatus = "kxsds"
    }
}

struct FDBuilding: Codable {
    let code: String
    let name: String
    let campusCode: String
    
    enum CodingKeys: String, CodingKey {
        case code = "教学楼代码"
        case name = "教学楼名称"
        case campusCode = "校区代码"
    }
}

struct FDCampus: Codable {
    let campusName: String
    let campusCode: String
    
    enum CodingKeys: String, CodingKey {
        case campusName = "校区代码"
        case campusCode = "校区名称"
    }
}
