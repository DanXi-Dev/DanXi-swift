import Foundation

/// API collection for eCard functionality.
public enum WalletAPI {
    
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
            if let element = try? decodeHTMLElement(data, selector: "#btn-agree-ok") {
                throw CampusError.termsNotAgreed
            }
            
            throw error
        }
    }
    
    /// Get user's eCard balance.
    public static func getBalance() async throws -> String {
        let url = URL(string: "https://ecard.fudan.edu.cn/epay/myepay/index")!
        let responseData = try await AuthenticationAPI.authenticateForData(url)
        let cashElement = try decodeHTMLElement(responseData, selector: ".payway-box-bottom-item > p")
        return try cashElement.html()
    }
    
    /// Get user's eCard transaction records.
    ///
    /// ## API Detail
    ///
    /// This API requires getting a CSRF string as parameter.
    /// The string will be cached in `CSRFStore`.
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
            
            guard let amount = try? element.child(3).html().replacingOccurrences(of: "&nbsp;", with: "") else {
                continue
            }
            
            guard let balance = try? element.child(5).child(0).html() else {
                continue
            }
            
            let transaction = Transaction(id: UUID(), date: date, location: location, amount: amount, remaining: balance)
            transactions.append(transaction)
        }

        return transactions
    }
}
