import Foundation
import SwiftUI
import Disk
import CryptoKit

struct LoadedImage {
    let image: Image
    let uiImage: UIImage
    let fileURL: URL
}

func loadImage(_ url: URL) async throws -> LoadedImage {
    if let loadedImage = await MemoryImageCache.shared.getImage(url) {
        return loadedImage
    }
    
    if let loadedImage = await DiskImageCache.shared.getImage(url) {
        return loadedImage
    }
    
    let (data, _) = try await URLSession.shared.data(from: url)
    guard let uiImage = UIImage(data: data) else { throw URLError(.badServerResponse) }
    let image = Image(uiImage: uiImage)
    let key = makeImageKey(url)
    let filename = "cachedimages/\(key).jpg"
    let fileURL = try Disk.url(for: filename, in: .caches)
    
    let loadedImage = LoadedImage(image: image, uiImage: uiImage, fileURL: fileURL)
    await MemoryImageCache.shared.setImage(url, loadedImage)
    try await DiskImageCache.shared.setImage(url, loadedImage)
    return loadedImage
}

func makeImageKey(_ url: URL) -> String {
    let hash = Insecure.MD5.hash(data: url.absoluteString.data(using: .utf8)!)
    return hash.map { String(format: "%02hhx", $0) }.joined()
}

actor DiskImageCache {
    static let shared = DiskImageCache()
    
    init() {
        Task(priority: .background) {
            await evict() // evict cache at app-start time
        }
    }
    
    func getImage(_ url: URL) -> LoadedImage? {
        let key = makeImageKey(url)
        let filename = "cachedimages/\(key).jpg"
        
        guard let fileURL = try? Disk.url(for: filename, in: .caches),
              let uiImage = try? Disk.retrieve(filename, from: .caches, as: UIImage.self) else {
            return nil
        }
        
        let image = Image(uiImage: uiImage)
        return LoadedImage(image: image, uiImage: uiImage, fileURL: fileURL)
    }
    
    nonisolated func getImageURL(_ url: URL) -> URL? {
        let key = makeImageKey(url)
        let filename = "cachedimages/\(key).jpg"
        guard let fileURL = try? Disk.url(for: filename, in: .caches), Disk.exists(fileURL) else {
            return nil
        }
        return fileURL
    }
    
    func setImage(_ url: URL, _ value: LoadedImage) throws {
        let key = makeImageKey(url)
        let filename = "cachedimages/\(key).jpg"
        
        try Disk.save(value.uiImage, to: .caches, as: filename)
    }
    
    func evict(before days: Int = 7) {
        let fileManager = FileManager.default
        var path = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        guard !path.isEmpty else { return }
        path[0].append(path: "cachedimages")
        
        do {
            let items = try fileManager.contentsOfDirectory(at: path[0], includingPropertiesForKeys: nil)
            for item in items {
                let attrs = try fileManager.attributesOfItem(atPath: item.path()) // FIXME: This API does not accept URL. It only accepts strings and some filenames could cause it to explode.
                let creationDate = attrs[FileAttributeKey.creationDate] as? Date
                guard let creationDate, let lastKeepDate = Calendar.current.date(byAdding: .day, value: -days, to: Date.now) else { return }
                if creationDate < lastKeepDate {
                    try fileManager.removeItem(at: item)
                }
            }
        } catch {
            
        }
    }
}

actor MemoryImageCache {
    static let shared = MemoryImageCache()
    
    let capacity: Int = 100
    
    private var cache: [String: LoadedImage] = [:]
    
    init() {
        cache.reserveCapacity(capacity)
    }
    
    func getImage(_ url: URL) -> LoadedImage? {
        cache[makeImageKey(url)]
    }
    
    func setImage(_ url: URL, _ value: LoadedImage) {
        if cache.count >= capacity {
            evict()
        }
        cache[makeImageKey(url)] = value
    }
    
    func evict() {
        cache = Dictionary(uniqueKeysWithValues: cache.suffix(capacity / 2))
        cache.reserveCapacity(capacity)
    }
}
