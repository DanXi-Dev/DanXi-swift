import Foundation

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    
    /// Decode a JSON file in bundle, assuming the file exist.
    /// - Parameter name: filename with no .json suffix.
    /// - Returns: Decoded object.
    func decodeData<T: Decodable>(_ name: String) -> T {
        let path = path(forResource: name, ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path))
        return try! JSONDecoder().decode(T.self, from: data)
    }
}
