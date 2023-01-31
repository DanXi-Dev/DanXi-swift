import Foundation

func decodeDate<K: CodingKey>(_ values: KeyedDecodingContainer<K>, key: KeyedDecodingContainer<K>.Key) throws -> Date {
    var iso8601TimeString = try values.decode(String.self, forKey: key)
    let formatter = ISO8601DateFormatter()
    
    if !iso8601TimeString.contains("+") && !iso8601TimeString.contains("Z") {
        iso8601TimeString.append("+00:00") // add timezone manually
    }
    
    if iso8601TimeString.contains(".") {
        formatter.formatOptions = [.withTimeZone, .withFractionalSeconds, .withInternetDateTime]
    } else {
        formatter.formatOptions = [.withTimeZone, .withInternetDateTime]
    }
    if let date = formatter.date(from: iso8601TimeString) {
        return date
    }
    throw NetworkError.invalidResponse
}
