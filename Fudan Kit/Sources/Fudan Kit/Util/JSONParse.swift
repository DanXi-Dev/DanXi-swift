import Foundation
import SwiftyJSON

/// Unwrap JSON data retrieved from campus server
/// - Returns: `JSON` object
///
/// Many campus API return a JSON struct with the following structure:
/// ```json
/// {
///     "e": 0, 
///     "m": "...".
///     "d": { ... }
/// }
/// ```
/// This function parse and unwrap the data part of that struct.
func unwrapJSON(_ data: Data) throws -> JSON {
    guard let json = try? JSON(data: data),
          let code = json["e"].int else {
        throw URLError(.badServerResponse)
    }
    
    if code != 0 {
        let message = json["m"].string ?? "Unknown"
        throw CampusError.customError(message: message)
    }
    
    return json["d"]
}

internal struct FDMyAPIJsonResponse: Codable {
    let data: [[String]]

    enum CodingKeys: String, CodingKey {
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decode([[String]].self, forKey: .data)
    }

    var dateValuePairs: [DateBoundValueData] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return data.compactMap { item in
            let targetItems = item.suffix(2)
            guard let dateString = targetItems.first, let valueString = targetItems.last,
                  let date = dateFormatter.date(from: dateString),
                  let value = Float(valueString) else {
                return nil
            }
            return DateBoundValueData(date: date, value: value)
        }
    }
}
