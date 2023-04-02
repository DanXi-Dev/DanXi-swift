import Foundation
import Disk

@propertyWrapper struct DiskCache<V: Codable> {
    struct StoredData: Codable {
        let value: V
        let createdAt: Date
    }

    let path: String
    let expire: TimeInterval?
    var cachedValue: V?
    
    init(_ path: String, expire: TimeInterval? = 60 * 60 * 24) {
        self.path = path
        self.expire = expire
    }

    var wrappedValue: V? {
        mutating get {
            // read value cached in memory
            if cachedValue != nil { return cachedValue }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let storedData = try? Disk.retrieve(path, from: .applicationSupport, as: StoredData.self, decoder: decoder) {
                // data will expire in given time interval, if time interval is nil, data won't expire
                guard Date.now.timeIntervalSince(storedData.createdAt) < expire ?? Double.infinity else {
                    return nil
                }
                
                cachedValue = storedData.value
                return storedData.value
            }
            return nil
        }
        set {
            if let newValue = newValue { // provide new value, store to disk
                cachedValue = newValue
                let storedData = StoredData(value: newValue, createdAt: Date.now)
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                do {
                    try Disk.save(storedData, to: .applicationSupport, as: path, encoder: encoder)
                } catch {}
            } else { // provide nil, remove data from disk
                cachedValue = nil
                do {
                    try Disk.remove(path, from: .applicationSupport)
                } catch {}
            }
        }
    }
}
