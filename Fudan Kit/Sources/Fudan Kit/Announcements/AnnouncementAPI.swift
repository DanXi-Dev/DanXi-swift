import Foundation
import SwiftSoup

/// API collection for academic office announcements (教务处通知)
///
/// ## Discussion
///
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
public enum AnnouncementAPI {
    static let academicOfficeURL = URL(string: "https://jwc.fudan.edu.cn")!
    
    public static func getAnnouncement(page: Int) async throws -> [Announcement] {
        let (data, _) = try await URLSession.campusSession.data(from: academicOfficeURL.appending(path: "/9397/list\(page).htm"))
        let elements = try decodeHTMLElementList(data, selector: ".wp_article_list_table > tbody > tr > td > table > tbody > tr:nth-child(1)")
        
        var announcements: [Announcement] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        for element in elements {
            do {
                let firstChild = try element.select("a")
                let title = try firstChild.html()
                let path = try firstChild.attr("href")
                let link = academicOfficeURL.appending(path: path)
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
}
