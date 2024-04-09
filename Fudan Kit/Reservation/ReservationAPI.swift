import Foundation
import SwiftSoup
import SwiftyJSON


/// API collection for playground reservation
public enum ReservationAPI {
    static let loginURL = URL(string: "https://elife.fudan.edu.cn/login2.action")!
    
    /// Get playgrounds for reservation.
    ///
    /// ## API Detail
    ///
    /// ### Categories
    ///
    /// In elife system, there are different categories. The categories can be retrieved by the
    /// API `https://elife.fudan.edu.cn/public/front/getLeftBody.htm`, the response is as following:
    /// ```json
    /// {
    ///   "code": 200,
    ///   "object": [
    ///     {
    ///       "NAME": "场馆预约",
    ///       "catType": 1,
    ///       "ISTHIRD": 0,
    ///       "ID": "2c9c486e4f821a19014f82381feb0001",
    ///       "hasIcon": "y"
    ///     },
    ///     {
    ///       "NAME": "教室借用",
    ///       "catType": 1,
    ///       "ISTHIRD": 0,
    ///       "ID": "2c9c486e4fa659ef014fa6dc7508005b",
    ///       "hasIcon": "y"
    ///     },
    ///     {
    ///       "NAME": "学生活动",
    ///       "catType": 1,
    ///       "ISTHIRD": 0,
    ///       "ID": "2c9c486e4fa659ef014fa6dd31ff005c",
    ///       "hasIcon": "y"
    ///     },
    ///     {
    ///       "NAME": "横幅位",
    ///       "catType": 1,
    ///       "ISTHIRD": 0,
    ///       "ID": "8aecc6ce56d1ef6b0156d4e627d71e5b",
    ///       "hasIcon": "y"
    ///     },
    ///     {
    ///       "NAME": "通知",
    ///       "catType": 2,
    ///       "ISTHIRD": 0,
    ///       "ID": "8aecc6ce7a9f47dc017adc3697a30fa2",
    ///       "hasIcon": "y"
    ///     },
    ///     {
    ///       "NAME": "宿舍电费",
    ///       "catType": 7,
    ///       "ISTHIRD": "",
    ///       "ID": "1",
    ///       "method": "rechargeElecteSelect",
    ///       "hasIcon": "n"
    ///     }
    ///   ],
    ///   "message": ""
    /// }
    /// ```
    /// Since our app only need to access category 场馆预约 and 学生活动,
    /// we can hardcode the category id into our code. The actual API is
    /// never called.
    ///
    /// ### Playground
    ///
    /// Given a category id, we can get the related playground using API
    /// `https://elife.fudan.edu.cn/public/front/search.htm?search=[playground-id]&pageBean.pageSize=100`.
    /// The response format is as follows:
    /// ```html
    /// <div class="order_list">
    ///     <table>
    ///         <tbody>
    ///             <tr>
    ///                 <td>
    ///                     <a href="/public/front/getDetailContent.htm?contentId=8aecc6ce7bc2eea5017bed81312c5f49&amp;categoryId=2c9c486e4f821a19014f82381feb0001"
    ///                         target="_blank">
    ///                         <img>...
    ///                     </a>
    ///                 </td>
    ///                 <td valign="top">
    ///                     <table width="100%" border="0" cellpadding="5">
    ///                         <tbody>
    ///                             <tr>
    ///                                 <th>服务项目：</th>
    ///                                 <td align="left">
    ///                                     <a href="/public/front/getDetailContent.htm?contentId=8aecc6ce7bc2eea5017bed81312c5f49&amp;categoryId=2c9c486e4f821a19014f82381feb0001">
    ///                                         杨詠曼楼琴房
    ///                                     </a>
    ///                                 </td>
    ///                             </tr>
    ///                             <tr>
    ///                                 <th>开放说明：</th>
    ///                                 <td></td>
    ///                             </tr>
    ///                             <tr>
    ///                                 <th>校区：</th>
    ///                                 <td>邯郸校区</td>
    ///                             </tr>
    ///                             <tr>
    ///                                 <th>运动项目：</th>
    ///                                 <td>琴房</td>
    ///                             </tr>
    ///                             <tr>
    ///                                 <td>
    ///                                     <a href="/public/front/toResourceFrame.htm?contentId=8aecc6ce7bc2eea5017bed81312c5f49">立即预订</a>
    ///                                 </td>
    ///                             </tr>
    ///                         </tbody>
    ///                     </table>
    ///                 </td>
    ///             </tr>
    ///         </tbody>
    ///     </table>
    ///     <table></table>
    ///     <table></table>
    ///     ...
    /// </div>
    /// ```
    public static func getPlaygrounds() async throws -> [Playground] {
        var result: [Playground] = []
        
        let ids = ["2c9c486e4f821a19014f82381feb0001", "2c9c486e4fa659ef014fa6dd31ff005c"] // hard-coded category ID
        
        for categoryId in ids {
            // get data from server
            var component = URLComponents(string: "https://elife.fudan.edu.cn/public/front/search.htm")!
            component.queryItems = [URLQueryItem(name: "id", value: categoryId), URLQueryItem(name: "pageBean.pageSize", value: "100")]
            let data = try await Authenticator.shared.authenticate(component.url!, manualLoginURL: loginURL)
            
            // parse data from HTML stirng
            let elements = try decodeHTMLElementList(data, selector: "div.order_list > table > tbody > tr > td > table > tbody")
            var playgrounds: [Playground] = []
            for element in elements {
                // match ID from link href query `contentId`
                guard let id = try? element
                    .select("tr > td > a")
                    .first()?
                    .attr("href")
                    .firstMatch(of: /contentId=(?<contentId>[A-Za-z0-9]+)/)?
                    .contentId else {
                    continue
                }
                
                guard let name = try? element.select("tr:nth-of-type(1) > td > a").html() else {
                    continue
                }
                
                // match campus from row with header 校区
                guard let campus = try? element
                    .select("tr")
                    .filter ({ (try? $0.children().first()?.html().contains("校区")) ?? false })
                    .first?
                    .child(1).html()
                    .replacing("&nbsp;", with: "") else {
                    continue
                }
                
                // match category from row with header 项目 (活动项目 or 运动项目)
                guard let category = try? element
                    .select("tr")
                    .filter ({ (try? $0.children().first()?.html().contains("项目")) ?? false })
                    .last? // first is 服务项目
                    .child(1).html()
                    .replacing("&nbsp;", with: "") else {
                    continue
                }
                
                // construct playground and append list
                let playground = Playground(id: String(id), name: name, campus: campus, category: category, categoryId: categoryId)
                playgrounds.append(playground)
            }
            
            result += playgrounds
        }
        
        return result
    }
    
    /// Get available reservations of a playground.
    ///
    /// ## API Detail
    ///
    /// The API
    /// `https://elife.fudan.edu.cn/public/front/getResource2.htm?contentId=[id]&currentDate=[YYYY-MM-dd]`
    /// will return the following HTML content:
    /// ```html
    /// <div class="hover" id="con_one_1" style="display: block; ">
    ///     <table class="site_table" cellpadding="0" cellspacing="0">
    ///         <tbody>
    ///             <tr class="site_tr">
    ///                 <td class="site_td1">
    ///                     <font>08:00</font>
    ///                     <br>
    ///                     09:00
    ///                 </td>
    ///                 <td class="site_td3">杨詠曼楼琴房</td>
    ///                 <td class="site_td4">
    ///                     <font>0</font>
    ///                     /
    ///                     <span>3</span>
    ///                 </td>
    ///                 <td class="site_td5">
    ///                                         &nbsp;</td>
    ///                 <td>&nbsp;</td>
    ///                 <td align="right">
    ///                     <img style="cursor:pointer" src="/images/front/index/button/reserve.gif" onclick="checkUser('xxxxx',this)"/>
    ///                 </td>
    ///             </tr>
    ///         </tbody>
    ///         <tbody>
    ///             ...
    ///         </tbody>
    ///     </table>
    /// </div>
    /// ```
    /// We use selector `#con_one_1 > table > tbody > tr` to locate the table.
    ///
    /// If the `img` tag has an `onclick` attribute, this represents that the playground can be reserved,
    /// and the identifier can be used to construct a link to the reservation form. If the attribute don't
    /// exist, this means that the playground cannot be reserved.
    public static func getReservations(playground: Playground, date: Date) async throws -> [Reservation] {
        // request data from server
        var component = URLComponents(string: "https://elife.fudan.edu.cn/public/front/getResource2.htm")!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        component.queryItems = [URLQueryItem(name: "contentId", value: playground.id),
                                URLQueryItem(name: "currentDate", value: dateFormatter.string(from: date))]
        let data = try await Authenticator.shared.authenticate(component.url!, manualLoginURL: loginURL)
        
        // check if is available
        guard let html = String(data: data, encoding: String.Encoding.utf8) else { return [] }
        if html.contains("无可预约场地") { return [] }
        
        // parse data
        let elements = try decodeHTMLElementList(data, selector: "#con_one_1 > table > tbody > tr")
        dateFormatter.dateFormat = "HH:mm"
        var reservations: [Reservation] = []
        for element in elements {
            guard let timeMatch = try? element
                .select("tr > td.site_td1")
                .first()?
                .html()
                .firstMatch(of: /.*(?<startTime>\d{2}+:\d{2}).*(?<endTime>\d{2}:\d{2})/) else {
                continue
            }
            
            guard let beginTime = dateFormatter.date(from: String(timeMatch.startTime)),
                  let endTime = dateFormatter.date(from: String(timeMatch.endTime)) else {
                continue
            }
            
            guard let name = try? element.select("td.site_td3").html() else { continue }
            
            guard let capacityMatch = try? element
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
            if let reserveIdMatch = try? element
                .select("img")
                .filter({ $0.hasAttr("onclick") })
                .first?
                .attr("onclick")
                .firstMatch(of: /checkUser\('(?<code>[A-Za-z0-9]+)',this\)/) {
                reserveId = String(reserveIdMatch.code)
            }
            
            let reservation = Reservation(id: UUID(), name: name, begin: beginTime, end: endTime, reserved: reserved, total: total, reserveId: reserveId, categoryId: playground.categoryId, playgroundId: playground.id)
            reservations.append(reservation)
        }
        
        return reservations
    }
}
