import Foundation
import SwiftyJSON
import SwiftSoup

// MARK: - Requests

struct FDPlaygroundAPI {
    static func login() async throws {
        let url = URL(string: "https://elife.fudan.edu.cn/login2.action")!
        _ = try await FDAuthAPI.auth(url: url)
    }
    
    static func getCategories() async throws -> [FDPlaygroundCategory] {
        let url = URL(string: "https://elife.fudan.edu.cn/public/front/getLeftBody.htm")!
        let (data, _) = try await sendRequest(URLRequest(url: url))
        let json = try JSON(data: data)
        return try JSONDecoder().decode([FDPlaygroundCategory].self, from: json["object"].rawData())
    }
    
    static func getPlaygroundList(category: FDPlaygroundCategory) async throws -> [FDPlayground] {
        // request data from server
        var component = URLComponents(string: "https://elife.fudan.edu.cn/public/front/search.htm")!
        component.queryItems = [URLQueryItem(name: "id", value: category.id),
                                URLQueryItem(name: "pageBean.pageSize", value: "100")]
        let (data, _) = try await sendRequest(URLRequest(url: component.url!))
        
        // parse data from HTML stirng
        let playgroundElements = try processHTMLDataList(data, selector: "div.order_list > table > tbody > tr > td > table > tbody")
        var rows: [FDPlayground] = []
        for row in playgroundElements {
            // match ID from link href query `contentId`
            guard let id = try? row
                .select("tr > td > a")
                .first()?
                .attr("href")
                .firstMatch(of: /contentId=(?<contentId>[A-Za-z0-9]+)/)?
                .contentId else {
                continue
            }
            
            guard let name = try? row.select("tr:nth-of-type(1) > td > a").html() else {
                continue
            }
            
            // match campus from row with header 校区
            guard let campus = try? row
                .select("tr")
                .filter ({ (try? $0.children().first()?.html().contains("校区")) ?? false })
                .first?
                .child(1).html()
                .replacing("&nbsp;", with: "") else {
                continue
            }
            
            // match category from row with header 项目 (活动项目 or 运动项目)
            guard let type = try? row
                .select("tr")
                .filter ({ (try? $0.children().first()?.html().contains("项目")) ?? false })
                .last? // first is 服务项目
                .child(1).html()
                .replacing("&nbsp;", with: "") else {
                continue
            }
            
            // construct playground and append list
            let playground = FDPlayground(id: String(id), name: name, campus: campus, type: type, categoryId: category.id)
            rows.append(playground)
        }
        
        return rows
    }
    
    static func getTimeSlotList(playground: FDPlayground, date: Date) async throws -> [FDPlaygroundTimeSlot] {
        // request data from server
        var component = URLComponents(string: "https://elife.fudan.edu.cn/public/front/getResource2.htm")!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        component.queryItems = [URLQueryItem(name: "contentId", value: playground.id),
                                URLQueryItem(name: "currentDate", value: dateFormatter.string(from: date))]
        let (data, _) = try await sendRequest(URLRequest(url: component.url!))
        
        // check if is available
        guard let html = String(data: data, encoding: String.Encoding.utf8) else { return [] }
        if html.contains("无可预约场地") { return [] }
        
        // parse data
        let rows = try processHTMLDataList(data, selector: "#con_one_1 > table > tbody > tr")
        var timeSlotList: [FDPlaygroundTimeSlot] = []
        for row in rows {
            guard let timeMatch = try? row
                .select("tr > td.site_td1")
                .first()?
                .html()
                .firstMatch(of: /.*(?<startTime>\d{2}+:\d{2}).*(?<endTime>\d{2}:\d{2})/) else {
                continue
            }
            
            guard let name = try? row.select("td.site_td3").html() else { continue }
            
            guard let capacityMatch = try? row
                .select("td.site_td4")
                .first()?
                .html()
                .firstMatch(of: /.*(?<reserved>\d+).*(?<total>\d+)/) else {
                continue
            }
            
            guard let reserved = Int(capacityMatch.reserved),
                  let total = Int(capacityMatch.total) else {
                continue
            }
            
            var reserveId: String?
            if let reserveIdMatch = try? row
                .select("img")
                .filter({ $0.hasAttr("onclick") })
                .first?
                .attr("onclick")
                .firstMatch(of: /checkUser\('(?<code>[A-Za-z0-9]+)',this\)/) {
                reserveId = String(reserveIdMatch.code)
            }
            
            let timeSlot = FDPlaygroundTimeSlot(name: name,
                                                beginTime: String(timeMatch.startTime),
                                                endTime: String(timeMatch.endTime),
                                                reserved: reserved,
                                                total: total,
                                                reserveId: reserveId,
                                                categoryId: playground.categoryId,
                                                playgroundId: playground.id)
            timeSlotList.append(timeSlot)
        }
        return timeSlotList
    }
}

// MARK: - Models

struct FDPlaygroundCategory: Codable {
    let id: String
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case name = "NAME"
    }
}

struct FDPlayground: Identifiable, Hashable {
    let id: String
    let name: String
    let campus: String
    let type: String
    let categoryId: String
}

struct FDPlaygroundTimeSlot: Identifiable {
    let id = UUID()
    
    let name: String
    let beginTime: String
    let endTime: String
    let reserved: Int
    let total: Int
    let reserveId: String?
    let categoryId: String
    let playgroundId: String
    
    var registerURL: URL? {
        guard let reserveId = reserveId else { return nil }
        var component = URLComponents(string: "https://elife.fudan.edu.cn/public/front/loadOrderForm_ordinary.htm")!
        component.queryItems = [URLQueryItem(name: "serviceContent.id", value: playgroundId),
                                URLQueryItem(name: "serviceCategory.id", value: categoryId),
                                URLQueryItem(name: "resourceIds", value: reserveId),
                                URLQueryItem(name: "codeStr", value: nil),
                                URLQueryItem(name: "orderCounts", value: "1")]
        return component.url!
    }
}
