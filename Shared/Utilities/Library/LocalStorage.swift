import Foundation

/// Wrap the system API for file management.
struct FileStore {
    static let caches = FileStore(directory: .cachesDirectory)
    static let applicationSupport = FileStore(directory: .applicationSupportDirectory)
    
    /// The base URL of a `FileStore` instance.
    let base: URL
    
    /// Initialize with URL provided.
    init(base: URL) {
        self.base = base
    }
    
    /// Initialize using standard system path.
    init(directory: FileManager.SearchPathDirectory) {
        self.base = try! FileManager.default.url(for: directory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
    
    /// Check if the file exists under base direcotry.
    /// - Parameter filename: filename.
    func fileExists(_ filename: String) -> Bool {
        let url = base.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: url.path())
    }
    
    
    /// Load data from file system and decode to designated type.
    /// - Parameter filename: filename.
    /// - Returns: Decoded object.
    func loadDecoded<T: Codable>(_ filename: String) throws -> T {
        let url = base.appendingPathComponent(filename)
        let file = try FileHandle(forReadingFrom: url)
        return try JSONDecoder().decode(T.self, from: file.availableData)
    }
    
    
    /// Load data from file system if file exist.
    /// - Parameter filename: filename.
    /// - Returns: Decoded object, `nil` if anything fails.
    func loadIfExsits<T: Codable>(_ filename: String) -> T? {
        do {
            if fileExists(filename) {
                return try loadDecoded(filename)
            }
            return nil
        } catch {
            return nil
        }
    }
    
    
    /// Encode and save object to file system.
    /// - Parameters:
    ///   - object: object to save.
    ///   - filename: filename.
    func saveEncoded<T: Codable>(_ object: T, filename: String) throws {
        let url = base.appendingPathComponent(filename)
        if !fileExists(filename) {
            FileManager.default.createFile(atPath: url.absoluteString, contents: nil)
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom({ date, encoder in
            var container = encoder.singleValueContainer()
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withTimeZone, .withFractionalSeconds, .withInternetDateTime]
            try container.encode(formatter.string(from: date))
        })
        let data = try encoder.encode(object)
        try data.write(to: url)
    }
    
    
    /// Delete file from filesystem.
    /// - Parameter filename: filename.
    func remove(_ filename: String) throws {
        let url = base.appendingPathExtension(filename)
        try FileManager.default.removeItem(at: url)
    }
}
