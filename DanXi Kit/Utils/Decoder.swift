import Foundation

extension JSONDecoder {
    static let defaultDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            var iso8601TimeString = dateString
            if !iso8601TimeString.contains("+") && !iso8601TimeString.contains("Z") {
                iso8601TimeString.append("+00:00") // add timezone manually
            }
            
            let formatter = ISO8601DateFormatter()
            if iso8601TimeString.contains(".") {
                formatter.formatOptions = [.withTimeZone, .withFractionalSeconds, .withInternetDateTime]
            } else {
                formatter.formatOptions = [.withTimeZone, .withInternetDateTime]
            }
            if let date = formatter.date(from: iso8601TimeString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        return decoder
    }()
}
