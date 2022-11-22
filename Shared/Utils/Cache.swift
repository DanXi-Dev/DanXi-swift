import Foundation

func cacheFileURL(filename: String) throws -> URL {
    try FileManager.default.url(for: .cachesDirectory,
                                in: .userDomainMask,
                                appropriateFor: nil,
                                create: false)
    .appendingPathComponent(filename)
}


/// Sava a codable object to cache directory.
/// - Parameters:
///   - object: Object to encode and cache.
///   - filename: Cache filename.
func saveData<T: Codable>(_ object: T?, filename: String) throws {
    let cacheURL = try cacheFileURL(filename: filename)
    // prepare encoder, set ISO8601 date format
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .custom({ date, encoder in
        var container = encoder.singleValueContainer()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withTimeZone, .withFractionalSeconds, .withInternetDateTime]
        try container.encode(formatter.string(from: date))
    })
    
    let data = try encoder.encode(object)
    try data.write(to: cacheURL)
}


/// Load data from existing cache.
/// - Parameter filename: Filename in cache directory.
/// - Returns: The cached object. Return `nil` if error occurs or file not exist.
func loadData<T: Codable>(filename: String) throws -> T {
    let cacheURL = try cacheFileURL(filename: filename)
    let file = try FileHandle(forReadingFrom: cacheURL)
    return try JSONDecoder().decode(T.self, from: file.availableData)
}


/// Remove cache data from file system.
/// - Parameter filename: Filename in cache directory.
func removeData(filename: String) throws {
    let cacheURL = try cacheFileURL(filename: filename)
    try FileManager.default.removeItem(at: cacheURL)
}
