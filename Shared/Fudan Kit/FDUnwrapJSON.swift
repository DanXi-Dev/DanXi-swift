import Foundation
import SwiftyJSON

func unwrapJSON(_ data: Data) throws -> JSON {
    guard let json = try? JSON(data: data),
          let code = json["e"].int else {
        throw ParseError.invalidJSON
    }
    
    if code != 0 {
        let message = json["m"].string ?? "Unknown"
        throw FDError.customError(message: message)
    }
    
    return json["d"]
}
