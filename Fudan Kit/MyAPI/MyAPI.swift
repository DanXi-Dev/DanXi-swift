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
