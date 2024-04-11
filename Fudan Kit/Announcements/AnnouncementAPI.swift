import Foundation
import SwiftSoup

/// API collection for academic office announcements (教务处通知)
///
/// ## Discussion
///
/// ### Undergraduate
/// The webpage for announcements is paged, the URLs of each page are
/// `https://jwc.fudan.edu.cn/9397/list1.htm`, `.../list2.htm`, etc.
///
/// The content of each page contains a table, which is a list of announcements.
/// ```html
/// <table class="wp_article_list_table">
///     <tbody>
///         <tr>
///             <td>
///                 <table>
///                     <tbody>
///                         <tr>
///                             <td>
///                                 <a href="/26/10/c25325a665104/page.htm" title="关于2024年春季学期学生评教时间安排的通知">关于2024年春季学期学生评教时间安排的通知</a>
///                             </td>
///                             <td class="ti">
///                                 2024-03-11                                             2024-03-11
///                             </td>
///                         </tr>
///                         ...
///                     </tbody>
///                 </table>
///             </td>
///         </tr>
///         ...
///     </tbody>
/// </table>
/// ```
/// To get the list of announcements, we should use CSS selector `.wp_article_list_table > tbody > tr > td > table > tbody > tr:nth-child(1)`.
/// In the selected element, the first child contains URL and title, and the second child contains date.
///
/// ### Postgraduate
/// The webpage for announcements is paged, the URLs of each page are
/// `https://gs.fudan.edu.cn/tzgg/list1.htm`, `.../list2.htm`, etc.
///
/// The content of each page contains a table, which is a list of announcements.
/// ```html
/// <ul class="wp_article_list">
///      <li class="list_item i1">
///          <div class="fields pr_fields">
///              <span class="Article_Index">1</span>
///              <span class="Article_Title"><a href="/59/71/c12939a481649/page.htm" target="_blank" title="通知 | 关于做好2022-2023学年第二学期结业转毕业工作的通知">通知 | 关于做好2022-2023学年第二学期结业转毕业工作的通知</a></span>
///          </div>
///          <div class="fields ex_fields">
///              <span class="Article_PublishDate">2023-02-13</span>
///          </div>
///      </li>
/// </ul>
/// </div>
/// ```
/// To get the list of announcements, we should use CSS selector  `#wp_news_w6 > ul > li.list_item`
public enum AnnouncementAPI {
    static let undergraduateAnnouncementURL = URL(string: "https://jwc.fudan.edu.cn")!
    static let postgraduateAnnouncementURL = URL(string: "https://gs.fudan.edu.cn")!
    
    public static func getUndergraduateAnnouncement(page: Int) async throws -> [Announcement] {
        let (data, _) = try await URLSession.campusSession.data(from: undergraduateAnnouncementURL.appending(path: "/9397/list\(page).htm"))
        let elements = try decodeHTMLElementList(data, selector: ".wp_article_list_table > tbody > tr > td > table > tbody > tr:nth-child(1)")
        
        var announcements: [Announcement] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        for element in elements {
            do {
                let firstChild = try element.select("a")
                let title = try firstChild.html()
                var path = try firstChild.attr("href")
                path = path.replacing(".htm", with: ".psp") // replace .htm with .psp to allow safari controller to directly login
                guard let link = URL(string: path, relativeTo: undergraduateAnnouncementURL) else { continue }
                let secondChild = try element.select("td.ti")
                guard let date = dateFormatter.date(from: try secondChild.html()) else { continue }
                let announcement = Announcement(id: UUID(), title: title, date: date, link: link)
                announcements.append(announcement)
            } catch {
                continue
            }
        }
        
        return announcements
    }
    
    public static func getPostgraduateAnnouncement(page: Int) async throws -> [Announcement] {
        let (data, _) = try await URLSession.campusSession.data(from: postgraduateAnnouncementURL.appending(path: "/tzgg/list\(page).htm"))
        let elements = try decodeHTMLElementList(data, selector: "#wp_news_w6 > ul > li.list_item")
        
        var announcements: [Announcement] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        for element in elements {
            do {
                let firstChild = try element.select("a")
                let title = try firstChild.html()
                let path = try firstChild.attr("href")
                guard let link = URL(string: path, relativeTo: postgraduateAnnouncementURL) else { continue }
                let secondChild = try element.select("div.fields.ex_fields > span")
                guard let date = dateFormatter.date(from: try secondChild.html()) else { continue }
                let announcement = Announcement(id: UUID(), title: title, date: date, link: link)
                announcements.append(announcement)
            } catch {
                continue
            }
        }

        return announcements
    }
}
