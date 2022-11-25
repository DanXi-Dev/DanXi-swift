import Foundation

extension URLRequest {
    mutating func setUserAgent() {
        if allHTTPHeaderFields == nil {
            allHTTPHeaderFields = ["User-Agent" : "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15"]
        } else {
            allHTTPHeaderFields!["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15"
        }
    }
}
