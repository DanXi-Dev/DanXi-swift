import Foundation

/// API collection for eCard functionality.
internal enum WalletAPI {
    
    /// Get the QR code for eCard spending.
    /// - Returns: A QR code string representation
    ///
    /// ## API Detail
    ///
    /// The QR code string is inside a element's `value` attribute with id `myText`.
    ///
    /// The user must first agree to terms and conditions to use this functionality. If not, the
    /// app should redirect user to proper webpage to agree.
    public static func getQRCode() async throws -> String {
        let url = URL(string: "https://ecard.fudan.edu.cn/epay/wxpage/fudan/zfm/qrcode")!
        let data = try await AuthenticationAPI.authenticateForData(url)
        
        do {
            let element = try decodeHTMLElement(data, selector: "#myText")
            return try element.attr("value")
        } catch {
            // handle case of user didn't agree to terms
            let document = try decodeHTMLDocument(data)
            if try document.select("#btn-agree-ok").first() != nil {
                throw CampusError.termsNotAgreed
            }
            
            throw error
        }
    }
    
    /// Get user's eCard balance and other info
    /// The server response is as follows:
    /// ```json
    /// {
    ///    "draw": 1,
    ///    "recordsTotal": 1,
    ///    "recordsFiltered": 1,
    ///    "data": [
    ///        [
    ///            "2030120342",
    ///            "李伟",
    ///            "正常",
    ///            "是(江湾;枫林;张江;邯郸)",
    ///            "2026-07-15",
    ///            "123.45"
    ///        ]
    ///    ]
    /// }
    /// ```
    public static func getUserInfo() async throws -> UserInfo {
        let url = URL(string: "https://my.fudan.edu.cn/data_tables/ykt_xx.json")!
        let _ = try await AuthenticationAPI.authenticateForData(url)
        let request = constructRequest(url, method: "POST")
        let (data, _) = try await URLSession.campusSession.data(for: request)
        let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        let userData = (dictionary["data"] as! [[String]])[0]
        return UserInfo(userId: userData[0], userName: userData[1], cardStatus: userData[2], entryPermission: userData[3], expirationDate: userData[4], balance: userData[5])
    }
    
    /// Get how much money user has spent each day
    /// The server response is as follows:
    /// {
    ///    "draw": 1,
    ///    "recordsTotal": 123,
    ///    "recordsFiltered": 123,
    ///    "data": [
    ///        [
    ///            "2024-03-18",
    ///            "33.44"
    ///        ],
    ///        [
    ///            "2024-03-17",
    ///            "12.68"
    ///        ]
    ///    ]
    /// }
    public static func getTransactionHistoryByDay() async throws -> [DateBoundValueData] {
        let url = URL(string: "https://my.fudan.edu.cn/data_tables/ykt_mrxf.json")!
        let _ = try await AuthenticationAPI.authenticateForData(url)
        let payload = "draw=1&columns%5B0%5D%5Bdata%5D=0&columns%5B0%5D%5Bname%5D=&columns%5B0%5D%5Bsearchable%5D=true&columns%5B0%5D%5Borderable%5D=false&columns%5B0%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B0%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B1%5D%5Bdata%5D=1&columns%5B1%5D%5Bname%5D=&columns%5B1%5D%5Bsearchable%5D=true&columns%5B1%5D%5Borderable%5D=false&columns%5B1%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B1%5D%5Bsearch%5D%5Bregex%5D=false&start=0&length=10&search%5Bvalue%5D=&search%5Bregex%5D=false"
        let request = constructRequest(url, payload: payload.data(using: .utf8))
        let (data, _) = try await URLSession.campusSession.data(for: request)
        return try JSONDecoder().decode(FDMyAPIJsonResponse.self, from: data).dateValuePairs
    }
    
    /// Get user's eCard transaction records.
    ///
    /// ## API Detail
    ///
    /// This API requires getting a CSRF string as parameter.
    /// The string will be cached in `CSRFStore`.
    ///
    /// The server response is as follows:
    /// ```html
    /// <table class="table table-striped table-hover">
    ///     <tbody>
    ///         <tr>
    ///             <td>
    ///                 <div>
    ///                     2001.01.01
    ///                 </div>
    ///                 <div class="span_2">
    ///                     12:00
    ///                 </div>
    ///             </td>
    ///             <td>&nbsp;
    ///                 <a href="/epay/consume/tradedetail?billno=..." class="span_1">水控消费</a>
    ///             </td>
    ///             <td>&nbsp;北区食堂</td>
    ///             <td>&nbsp;10.00</td>
    ///             <td>&nbsp;100.00</td>
    ///             ...
    ///         </tr>
    ///     </tbody>
    /// </table>
    /// ```
    public static func getTransactions(page: Int) async throws -> [Transaction] {
        actor CSRFStore {
            static let shared = CSRFStore()
            
            var csrf: String?
            
            func getCSRF() async throws -> String {
                if let csrf = csrf {
                    return csrf
                }
                
                let url = URL(string: "https://ecard.fudan.edu.cn/epay/consume/index")!
                let responseData = try await AuthenticationAPI.authenticateForData(url)
                let element = try decodeHTMLElement(responseData, selector: "meta[name=\"_csrf\"]")
                let csrf = try element.attr("content")
                self.csrf = csrf
                return csrf
            }
        }
        
        let csrf = try await CSRFStore.shared.getCSRF()
        let url = URL(string: "https://ecard.fudan.edu.cn/epay/consume/query")!
        let form = ["pageNo": String(page), "_csrf": csrf]
        let request = constructFormRequest(url, form: form)
        
        let (data, _) = try await URLSession.campusSession.data(for: request)
        
        let table = try decodeHTMLElement(data, selector: "#all tbody")
        var transactions: [Transaction] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY.MM.dd HH:mm"
        for element in table.children() {
            guard let dateString = try? element.child(0).child(0).html().trimmingCharacters(in: .whitespacesAndNewlines),
                  let timeString = try? element.child(0).child(1).html().trimmingCharacters(in: .whitespacesAndNewlines),
                  let date = dateFormatter.date(from: "\(dateString) \(timeString)") else {
                continue
            }
            
            guard let location = try? element.child(2).html().replacingOccurrences(of: "&nbsp;", with: "") else {
                continue
            }
            
            guard let amountString = try? element.child(3).html().replacingOccurrences(of: "&nbsp;", with: ""),
                  let amount = Double(amountString) else {
                continue
            }
            
            guard let balanceString = try? element.child(4).html().replacingOccurrences(of: "&nbsp;", with: ""),
                  let balance = Double(balanceString) else {
                continue
            }
            
            let transaction = Transaction(id: UUID(), date: date, location: location, amount: amount, remaining: balance)
            transactions.append(transaction)
        }
        
        return transactions
    }
}
