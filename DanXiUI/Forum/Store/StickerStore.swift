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
                let loadedImage = try await retrieveImage(sticker: sticker)
                stickerImage[sticker.id] = loadedImage
            } catch _ as URLError {
                continue // ignore network error, sticker loading failed should not be fatal
            }
        }
        
        Task {
            try clearUnunsed(stickers: stickers)
        }
    }
    
    private func retrieveImage(sticker: Sticker) async throws -> LoadedImage {
        let filename = "stickers/\(sticker.sha256).jpg"
        
        let fileURL = try Disk.url(for: filename, in: .caches)
        
        // retrieved from disk
        if let uiImage = try? Disk.retrieve(filename, from: .caches, as: UIImage.self) {
            let image = Image(uiImage: uiImage)
            return LoadedImage(image: image, uiImage: uiImage, fileURL: fileURL)
        }
        
        // download image from internet
        let (data, _) = try await URLSession.shared.data(from: sticker.url)
        guard let uiImage = UIImage(data: data) else {
            throw LocatableError()
        }
        try Disk.save(uiImage, to: .caches, as: filename)
        let image = Image(uiImage: uiImage)
        
        return LoadedImage(image: image, uiImage: uiImage, fileURL: fileURL)
    }
    
    private func clearUnunsed(stickers: [Sticker]) throws {
        let fileManager = FileManager.default
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        guard var path = paths.first else { return }
        path.append(path: "stickers")
        
        let items = try fileManager.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
        for item in items {
            let filename = item.lastPathComponent
            for sticker in stickers {
                if filename.starts(with: sticker.sha256) {
                    try? fileManager.removeItem(at: item)
                }
            }
        }
    }
}

struct LoadedImage {
    let image: Image
    let uiImage: UIImage
    let fileURL: URL
}
