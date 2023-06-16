import Foundation
import SwiftSoup

struct FDLibraryAPI {
    static func getLibrarySeats() async throws -> [Int] {
        // cannot access from outside campus
        let url = URL(string: "https://webvpn.fudan.edu.cn/http/77726476706e69737468656265737421a1a70fc9727e39002f46dffe/book/show")!
        let (data, _) = try await sendRequest(URLRequest(url: url))
        let elementList = try processHTMLDataList(data, selector: "div.ceng.nowap > span:nth-child(1)")
        var libraryPeopleList = [0, 0, 0, 0, 0] // 文图，理图，张江，枫林，江湾
        var idx = 0
        for library in elementList {
            guard idx < libraryPeopleList.count else { break }
            guard let content = try? library.html() else { continue }
            guard let number = Int(content.trimmingPrefix("当前在馆人数：")) else { continue }
            libraryPeopleList[idx] = number
            idx += 1
        }
        
        return libraryPeopleList
    }
}
