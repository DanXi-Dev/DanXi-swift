import Foundation
import SwiftSoup
import UIKit


struct FDECardAPI {
    static var csrf: String?
    
    static func getQRCodeString() async throws -> String {
        let url = URL(string: "https://ecard.fudan.edu.cn/epay/wxpage/fudan/zfm/qrcode")!
        let responseData = try await FDAuthAPI.auth(url: url)
        
        let qrcodeElement = try processHTMLData(responseData, selector: "#myText")
        let qrcodeStr = try qrcodeElement.attr("value")
        return qrcodeStr
    }
    
    static func getBalance() async throws -> String {
        let url = URL(string: "https://ecard.fudan.edu.cn/epay/myepay/index")!
        let responseData = try await FDAuthAPI.auth(url: url)
        let cashElement = try processHTMLData(responseData, selector: ".payway-box-bottom-item > p")
        return try cashElement.html()
    }
    
    static func getCSRF() async throws {
        let url = URL(string: "https://ecard.fudan.edu.cn/epay/consume/index")!
        let responseData = try await FDAuthAPI.auth(url: url)
        let csrfElement = try processHTMLData(responseData, selector: "meta[name=\"_csrf\"]")
        csrf = try csrfElement.attr("content")
    }
    
    static func getTransactions(page: Int = 1) async throws -> [FDTransaction] {
        guard let csrf = csrf else {
            return []
        }
        
        let queryForm = [
            URLQueryItem(name: "pageNo", value: String(page)),
            URLQueryItem(name: "_csrf", value: csrf)
        ]
        let request = prepareFormRequest(URL(string: "https://ecard.fudan.edu.cn/epay/consume/query")!, form: queryForm)
        let (responseData, _) = try await sendRequest(request)
        
        let tableBody = try processHTMLData(responseData, selector: "#all tbody")
        
        var tradeRecords: [FDTransaction] = []
        for row in tableBody.children() {
            let record = FDTransaction(createTime: "\(try row.child(0).child(0).html()) \(try row.child(0).child(1).html())",
                                       location: try row.child(2).html().replacingOccurrences(of: "&nbsp;", with: ""),
                                       amount: try row.child(3).html().replacingOccurrences(of: "&nbsp;", with: ""),
                                       balance: try row.child(5).child(0).html())
            tradeRecords.append(record)
        }
        
        return tradeRecords
    }
}

struct FDTransaction: Identifiable, Equatable {
    let id = UUID()
    let createTime: String
    let location: String
    let amount: String
    let balance: String
}
