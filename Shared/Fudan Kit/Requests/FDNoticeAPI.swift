import Foundation

struct FDNoticeAPI {
    static func getNoticeList(_ idx: Int) async throws -> [FDNotice] {
        let (data, _) = try await sendRequest("https://jwc.fudan.edu.cn/9397/list\(idx).htm")
        let elements = try processHTMLDataList(data, selector: ".wp_article_list_table > tbody > tr > td > table > tbody > tr:nth-child(1)")
        var noticeList: [FDNotice] = []
        for element in elements {
            do {
                let linkElement = try element.select("a")
                let name = try linkElement.html()
                let path = try linkElement.attr("href")
                let urlString = ("https://jwc.fudan.edu.cn" + path).replacing(".htm", with: ".psp")
                guard let url = URL(string: urlString) else { continue }
                let dateElement = try element.select("td.ti")
                let date = try dateElement.html()
                let notice = FDNotice(title: name, date: date, link: url)
                noticeList.append(notice)
            } catch {
                continue
            }
        }
        
        return noticeList
    }
    
    static func authenticate(_ url: URL) async throws -> URL {
        return try await FDAuthAPI.authURL(url: url)
    }
}


struct FDNotice: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let link: URL
}
