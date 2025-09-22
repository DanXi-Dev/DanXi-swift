import Foundation
import Utils
import SwiftSoup

/// API collection for eCard functionality.
public enum WalletAPI {
    
    static let loginURL = URL(string: "https://ecard.fudan.edu.cn/epay/")!
    
    /// Get the QR code for eCard spending.
    /// FIXME: The authentication method for this API has been updated, it's not currently available.
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
        let data = try await Authenticator.neo.authenticate(url)
        
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
    
    public static func getContent() async throws -> WalletContent {
        let pageURL = URL(string: "https://ecard.fudan.edu.cn/epay/myepay/index")!
        let authenticateURL = URL(string: "https://ecard.fudan.edu.cn/epay/j_spring_cas_security_check")!
        let data = try await Authenticator.classic.authenticate(pageURL, loginURL: authenticateURL)
        
        let document = try decodeHTMLDocument(data)

        let balance = try parseBalance(document)
        let transactions = try parseTransactions(document)
        let logs = try parseStatistics(document)
        
        return WalletContent(balance: balance, transactions: transactions, logs: logs)
    }
    
    private static func parseBalance(_ document: Document) throws -> String {
        let balanceElement = try document.select(".payway-box-bottom .payway-box-bottom-item:first-child p:first-child")
        return try balanceElement.text()
    }
    
    private static func parseTransactions(_ document: Document) throws -> [Transaction] {
        guard let table = try document.select("#all tbody").first() else {
            throw LocatableError()
        }
        
        var transactions: [Transaction] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY.MM.dd HH:mm"
        for element in table.children() {
            guard let dateString = try? element.child(0).child(0).html().trimmingCharacters(in: .whitespacesAndNewlines),
                  let timeString = try? element.child(0).child(1).html().trimmingCharacters(in: .whitespacesAndNewlines),
                  let date = dateFormatter.date(from: "\(dateString) \(timeString)") else {
                continue
            }
            
            guard let categoryString = try? element.child(1).text().replacingOccurrences(of: "&nbsp;", with: ""),
                  let sign = categoryString.hasSuffix("消费") ? "-" : "+" else {
                continue
            }
            
            guard let location = try? element.child(2).html().replacingOccurrences(of: "&nbsp;", with: "") else {
                continue
            }
            
            guard let amountString = try? element.child(3).html().replacingOccurrences(of: "&nbsp;", with: "").trimmingCharacters(in: .whitespacesAndNewlines),
                  let amount = Double(amountString) else {
                continue
            }
            
            guard let balanceString = try? element.child(4).html().replacingOccurrences(of: "&nbsp;", with: "").trimmingCharacters(in: .whitespacesAndNewlines),
                  let balance = Double(balanceString) else {
                continue
            }
            
            let transaction = Transaction(id: UUID(), date: date, location: location, amount: amount, remaining: balance, sign: sign)
            transactions.append(transaction)
        }

        return transactions
    }
    
    private struct WalletStatisticsResponse: Decodable {
        let termdate: String
        let custid: Int
        let amount: Float
    }
    
    private static func parseStatistics(_ document: Document) throws -> [WalletLog] {
        guard let element = try document.getElementById("transLst") else {
            throw LocatableError()
        }
        
        guard let data = try element.attr("value").data(using: String.Encoding.utf8) else {
            throw LocatableError()
        }
        let decoded = try JSONDecoder().decode([WalletStatisticsResponse].self, from: data)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYYMMdd"
        
        return decoded.compactMap {
            guard let date = dateFormatter.date(from: $0.termdate) else {
                return nil
            }
            
            return WalletLog(id: UUID(), date: date, amount: $0.amount)
        }
    }
    
    /// Get user's eCard balance.
    ///
    /// This API is slower than ``MyAPI.getUserInfo()``, which should be preferred.
    public static func getBalance() async throws -> String {
        let url = URL(string: "https://ecard.fudan.edu.cn/epay/myepay/index")!
        let responseData = try await Authenticator.classic.authenticate(url, loginURL: loginURL)
        let cashElement = try decodeHTMLElement(responseData, selector: ".payway-box-bottom-item > p")
        return try cashElement.html()
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
                let responseData = try await Authenticator.classic.authenticate(url, loginURL: WalletAPI.loginURL)
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
        
        let data = try await Authenticator.classic.authenticate(request, loginURL: loginURL)
        
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
            
            guard let categoryString = try? element.child(1).text().replacingOccurrences(of: "&nbsp;", with: ""),
                  let sign = categoryString.hasSuffix("消费") ? "-" : "+" else {
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
            
            let transaction = Transaction(id: UUID(), date: date, location: location, amount: amount, remaining: balance, sign: sign)
            transactions.append(transaction)
        }

        return transactions
    }
}
