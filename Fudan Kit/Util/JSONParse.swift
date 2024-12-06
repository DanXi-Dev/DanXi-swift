import Foundation
import SwiftyJSON
import Utils

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
        throw LocatableError()
    }
    
    if code != 0 {
        let message = json["m"].string ?? "Unknown"
        throw CampusError.customError(message: message)
    }
    
    return json["d"]
}
