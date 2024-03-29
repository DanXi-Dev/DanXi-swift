import Foundation
import SwiftyJSON

// MARK: - Requests

struct FDBusAPI {
    static func fetchBusRoutes() async throws -> [FDBusRoute] {
        let url = URL(string: "https://zlapp.fudan.edu.cn/fudanbus/wap/default/lists")!
        let responseData = try await FDAuthAPI.auth(url: url)
        let routeData = try unwrapJSON(responseData)["data"].rawData()
        return try processJSONData(routeData)
    }
    
    static func fetchHolidayRoutes() async throws -> [FDBusRoute] {
        let url = URL(string: "https://zlapp.fudan.edu.cn/fudanbus/wap/default/lists")!
        let request = prepareFormRequest(url, form: [URLQueryItem(name: "holiday", value: "1")])
        let (data, _) = try await sendRequest(request)
        let routeData = try unwrapJSON(data)["data"].rawData()
        return try processJSONData(routeData)
    }
}

// MARK: - Model

struct FDBusRoute: Codable {
    let route: String
    let lists: [FDBusSchedule]
    
    func match(start: String, end: String) -> Bool {
        if start == end {
            return false
        }
        let stations = Set(route.components(separatedBy: "-"))
        return stations.contains(start) && stations.contains(end)
    }
}


struct FDBusSchedule: Identifiable, Codable {
    let id: Int
    let start: String
    let end: String
    let startTime: Date?
    let endTime: Date?
    let arrow: Int
    let holiday: Int
    var missed = false
    
    func match(start: String, end: String) -> Bool {
        return (self.start == start && startTime != nil) || (self.end == start && endTime != nil)
    }
    
    func startAt(from: String) -> Date? {
        let reversed = from != start
        
        if !reversed {
            guard arrow == 1 || arrow == 3 else { return nil }
            return startTime
        } else {
            guard arrow == 1 || arrow == 2 else { return nil }
            return endTime
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, arrow, holiday, start, end
        case startTime = "stime"
        case endTime = "etime"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        self.id = Int(id) ?? 0
        let arrow = try container.decode(String.self, forKey: .arrow)
        self.arrow = Int(arrow) ?? 0
        let holiday = try container.decode(String.self, forKey: .holiday)
        self.holiday = Int(holiday) ?? 0
        self.start = try container.decode(String.self, forKey: .start)
        self.end = try container.decode(String.self, forKey: .end)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        self.startTime = dateFormatter.date(from: try container.decode(String.self, forKey: .startTime))
        self.endTime = dateFormatter.date(from: try container.decode(String.self, forKey: .endTime))
    }
}
