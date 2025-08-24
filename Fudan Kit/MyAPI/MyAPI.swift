import Foundation
import SwiftyJSON
import Utils

/// API collection from `my.fudan.edu.cn`.
/// This API collection has some duplicated functions, but it is 
/// preferred for better performance.
///
/// - Important:
///     ``login()`` should be called before invoking any API.
///
/// This API collection includes the following functions:
/// - Canteen
/// - ECard balance & spending history
/// - Electricity usage
public enum MyAPI {
    static let loginURL = URL(string: "https://my.fudan.edu.cn")!
    
    /// API for daily electricity usage
    /// - Returns: A list of ``ElectricityLog``, which contains a date and the electricity used in this date
    ///
    /// This API use data format prescribed in ``DateValue``
    public static func getElectricityLogs() async throws -> [ElectricityLog] {
        let url = URL(string: "https://my.fudan.edu.cn/data_tables/ykt_xszsqyydqk.json")!
        // a magical payload discovered by @singularity-s0
        let payload = "draw=1&columns%5B0%5D%5Bdata%5D=0&columns%5B0%5D%5Bname%5D=&columns%5B0%5D%5Bsearchable%5D=true&columns%5B0%5D%5Borderable%5D=false&columns%5B0%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B0%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B1%5D%5Bdata%5D=1&columns%5B1%5D%5Bname%5D=&columns%5B1%5D%5Bsearchable%5D=true&columns%5B1%5D%5Borderable%5D=false&columns%5B1%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B1%5D%5Bsearch%5D%5Bregex%5D=false&start=0&length=10&search%5Bvalue%5D=&search%5Bregex%5D=false"
        let request = constructRequest(url, payload: payload.data(using: .utf8))
        let data = try await Authenticator.neo.authenticate(request, loginURL: loginURL)
        let dateValues = try decodeMyAPIResponse(data: data)
        return dateValues.map { dateValue in
            ElectricityLog(id: UUID(), date: dateValue.date, usage: dateValue.value)
        }
    }
    
    /// API for daily ecard spending
    /// - Returns: A list of ``WalletLog``, which contains a date and the money spent in this date
    ///
    /// This API use data format prescribed in ``DateValue``
    public static func getWalletLogs() async throws -> [WalletLog] {
        let url = URL(string: "https://my.fudan.edu.cn/data_tables/ykt_mrxf.json")!
        // a magical payload discovered by @singularity-s0
        let payload = "draw=1&columns%5B0%5D%5Bdata%5D=0&columns%5B0%5D%5Bname%5D=&columns%5B0%5D%5Bsearchable%5D=true&columns%5B0%5D%5Borderable%5D=false&columns%5B0%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B0%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B1%5D%5Bdata%5D=1&columns%5B1%5D%5Bname%5D=&columns%5B1%5D%5Bsearchable%5D=true&columns%5B1%5D%5Borderable%5D=false&columns%5B1%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B1%5D%5Bsearch%5D%5Bregex%5D=false&start=0&length=10&search%5Bvalue%5D=&search%5Bregex%5D=false"
        let request = constructRequest(url, payload: payload.data(using: .utf8))
        let data = try await Authenticator.neo.authenticate(request, loginURL: loginURL)
        let dateValues = try decodeMyAPIResponse(data: data)
        return dateValues.map { dateValue in
            WalletLog(id: UUID(), date: dateValue.date, amount: dateValue.value)
        }
    }
    
    /// Get user's eCard balance and other info
    ///
    /// The server response is as follows:
    /// ```json
    /// {
    ///    "draw": 1,
    ///    "recordsTotal": 1,
    ///    "recordsFiltered": 1,
    ///    "data": [
    ///        [
    ///            "2030*****",
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
        let request = constructRequest(url, method: "POST")
        let data = try await Authenticator.neo.authenticate(request, loginURL: loginURL)
        
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let userDataList = (dictionary["data"] as? [[String]]), !userDataList.isEmpty else {
            throw LocatableError()
        }
        
        let userData = userDataList[0]
        guard userData.count >= 6 else {
            throw LocatableError()
        }
        
        return UserInfo(userId: userData[0], userName: userData[1], cardStatus: userData[2], entryPermission: userData[3], expirationDate: userData[4], balance: userData[5])
    }
    
    
    /// Decode reponse for multiple APIs.
    ///
    /// The server response is as follows:
    /// ```json
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
    /// ```
    private static func decodeMyAPIResponse(data: Data) throws -> [DateValue] {
        let json = JSON(data)
        let valuesData = try json["data"].rawData()
        let values = try JSONDecoder().decode([[String]].self, from: valuesData)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return values.compactMap { item in
            let targetItems = item.suffix(2)
            guard let dateString = targetItems.first, 
                    let valueString = targetItems.last,
                  let date = dateFormatter.date(from: dateString),
                  let value = Float(valueString) else {
                return nil
            }
            return DateValue(date: date, value: value)
        }
    }
    
    /// Struct used in multiple MyAPI responses, including electricity usage and ecard spending
    private struct DateValue: Codable {
        public let date: Date
        public let value: Float
    }
}
