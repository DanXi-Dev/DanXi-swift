import Utils
import SwiftUI
import Disk

class StickerStore: ObservableObject {
    static let shared = StickerStore()
    
    var stickers: [Sticker]
    var stickerSet: Set<String>
    var stickerImage: [String: LoadedImage]
    
    init() {
        stickers = []
        stickerImage = [:]
        stickerSet = []
    }
    
    func initialize() async throws {
        if ConfigurationCenter.configuration.stickers.isEmpty {
            try await ConfigurationCenter.refresh()
        }
        
        self.stickers = ConfigurationCenter.configuration.stickers
        self.stickerSet = Set(stickers.map(\.id))
        
        for sticker in stickers {
            do {
                let loadedImage = try await retrieveImage(sticker: sticker, scale: 0.4)
                stickerImage[sticker.id] = loadedImage
            } catch _ as URLError {
                continue // ignore network error, sticker loading failed should not be fatal
            }
        }
        
        Task {
            try clearUnunsed(stickers: stickers)
        }
    }
    
    private func retrieveImage(sticker: Sticker, scale: CGFloat = 1.0) async throws -> LoadedImage {
        let pathExtension = sticker.url.pathExtension.isEmpty ? "webp" : sticker.url.pathExtension.lowercased()
        let filename = "stickers/\(sticker.sha256).\(pathExtension)"
        
        let fileURL = try Disk.url(for: filename, in: .caches)
        
        // retrieved from disk
        if let uiImage = try? Disk.retrieve(filename, from: .caches, as: UIImage.self) {
            let scaledUIImage = scaleImage(uiImage, by: scale)
            let image = Image(uiImage: scaledUIImage)
            return LoadedImage(image: image, uiImage: scaledUIImage, fileURL: fileURL)
        }
        
        // download image from internet
        let (data, _) = try await URLSession.defaultSession.data(from: sticker.url)
        guard let uiImage = UIImage(data: data) else {
            throw LocatableError()
        }
        try Disk.save(data, to: .caches, as: filename)
        
        let scaledUIImage = scaleImage(uiImage, by: scale)
        let image = Image(uiImage: scaledUIImage)
        
        return LoadedImage(image: image, uiImage: scaledUIImage, fileURL: fileURL)
    }
    
    private func scaleImage(_ image: UIImage, by scale: CGFloat) -> UIImage {
        guard scale > 0, scale != 1 else { return image }
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    private func clearUnunsed(stickers: [Sticker]) throws {
        let fileManager = FileManager.default
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        guard var path = paths.first else { return }
        path.append(path: "stickers")
        let activeHashes = Set(stickers.map(\.sha256))
        
        let items = try fileManager.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
        for item in items {
            // Remove legacy transcoded caches because stickers are now stored as original WEBP data.
            if ["jpg", "jpeg"].contains(item.pathExtension.lowercased()) {
                try? fileManager.removeItem(at: item)
                continue
            }
            
            let filename = item.deletingPathExtension().lastPathComponent
            if !activeHashes.contains(filename) {
                try? fileManager.removeItem(at: item)
            }
        }
    }
}

struct LoadedImage {
    let image: Image
    let uiImage: UIImage
    let fileURL: URL
}
