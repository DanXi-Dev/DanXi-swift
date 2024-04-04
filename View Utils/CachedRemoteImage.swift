import SwiftUI
import SensitiveContentAnalysis
import Disk

actor MemoryImageCache {
    let capacity: Int = 100
    
    static public let shared = MemoryImageCache()
    // [Key : (Image, isSensitive)]
    private var cache: [String: (CachedRemoteImage.LoadedImage, Bool)] = [:]
    
    init() {
        cache.reserveCapacity(capacity)
    }
    
    public func getImage(_ key: String) -> (CachedRemoteImage.LoadedImage, Bool)? {
        cache[key]
    }
    
    public func setImage(_ key: String, _ value: (CachedRemoteImage.LoadedImage, Bool)) {
        if cache.count >= capacity {
            evict()
        }
        cache[key] = value
    }
    
    func evict() {
        cache = Dictionary(uniqueKeysWithValues: cache.suffix(capacity / 2))
        cache.reserveCapacity(capacity)
    }
}

public struct CachedRemoteImage: View {
    @State private var showSensitive = false
    
    enum LoadingStatus {
        case loading
        case error(error: Error)
        case loaded(image: LoadedImage, sensitive: Bool)
    }
    
    struct LoadedImage {
        let image: Image
        let uiImage: UIImage
        let fileURL: URL
    }
    
    public init(_ url: URL) {
        self.url = url
    }
    
    private let url: URL
    @State private var loadingStatus: LoadingStatus = .loading
    
    @MainActor
    func setLoadingStatus(_ status: LoadingStatus) {
        loadingStatus = status
    }
    
    public static func evictCache(daysToKeep: Int = 7) {
        let fm = FileManager.default
        var path = fm.urls(for: .cachesDirectory, in: .userDomainMask)
        guard !path.isEmpty else { return }
        path[0].append(path: "cachedimages")
        do {
            let items = try fm.contentsOfDirectory(at: path[0], includingPropertiesForKeys: nil)
            for item in items {
                let attrs = try fm.attributesOfItem(atPath: item.path()) // FIXME: This API does not accept URL. It only accepts strings and some filenames could cause it to explode.
                let creationDate = attrs[FileAttributeKey.creationDate] as? Date
                guard let creationDate, let lastKeepDate = Calendar.current.date(byAdding: .day, value: -daysToKeep, to: Date.now) else { return }
                if creationDate < lastKeepDate {
                    try fm.removeItem(at: item)
                }
            }
        } catch {
            // print("Failed to evict cache \(error)")
        }
    }
    
    func loadImage() {
        Task(priority: .medium) {
            do {
                await setLoadingStatus(.loading)
                let name = url.absoluteString.data(using: .utf8)!.base64EncodedString()
                let filename = "cachedimages/\(name).jpg"
                let sensitiveMarker = filename + "-sensitive"
                
                // Retrieve from memory first
                if let (loadedImage, sensitive) = await MemoryImageCache.shared.getImage(filename) {
                    await setLoadingStatus(.loaded(image: loadedImage, sensitive: sensitive))
                    return
                }
                
                // Retrive cache from disk
                if let fileURL = try? Disk.url(for: filename, in: .caches),
                   let uiImage = try? Disk.retrieve(filename, from: .caches, as: UIImage.self) {
                    let image = Image(uiImage: uiImage)
                    let loadedImage = LoadedImage(image: image, uiImage: uiImage, fileURL: fileURL)
                    let sensitive = Disk.exists(sensitiveMarker, in: .caches)
                    await MemoryImageCache.shared.setImage(filename, (loadedImage, sensitive))
                    await setLoadingStatus(.loaded(image: loadedImage, sensitive: sensitive))
                    return
                }
                
                // Download from internet
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let uiImage = UIImage(data: data) else { throw URLError(.badServerResponse) }
                let image = Image(uiImage: uiImage)
                try Disk.save(uiImage, to: .caches, as: filename)
                let fileURL = try Disk.url(for: filename, in: .caches)
                let loadedImage = LoadedImage(image: image, uiImage: uiImage, fileURL: fileURL)
                let sensitive = await analyzeSensitiveIfAvailable(fileURL)
                if sensitive {
                    // Create a file to mark sensitive
                    try? Disk.save("", to: .caches, as: sensitiveMarker)
                }
                await MemoryImageCache.shared.setImage(filename, (loadedImage, sensitive))
                await setLoadingStatus(.loaded(image: loadedImage, sensitive: sensitive))
            } catch {
                loadingStatus = .error(error: error)
            }
        }
    }
    
    func analyzeSensitiveIfAvailable(_ at: URL) async -> Bool {
        guard #available(iOS 17, *) else { return false }
        let analyzer = SCSensitivityAnalyzer()
        let policy = analyzer.analysisPolicy
        if policy == .disabled { return false }
        let response = try? await analyzer.analyzeImage(at: url)
        guard let response else { return false }
        return response.isSensitive
    }
    
    public var body: some View {
        switch loadingStatus {
        case .loading:
            ProgressView()
                .frame(width: 300, height: 300)
                .background(Color.gray.opacity(0.2))
                .onAppear {
                    loadImage()
                }
        case .error:
            Button(action: loadImage) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .frame(width: 300, height: 300)
                    .background(Color.gray.opacity(0.2))
            }
        case .loaded(let loaded, let sensitive):
            if sensitive && !showSensitive {
                Button(action:  {
                    withAnimation {
                        showSensitive = true
                    }
                }) {
                    ZStack(alignment: .center, content: {
                        ImageViewer(image: loaded)
                            .blur(radius: 30.0)
                            .clipped()
                            .allowsHitTesting(false)
                        
                        Image(systemName: "eye.trianglebadge.exclamationmark")
                            .font(.largeTitle)
                            .foregroundColor(.primary)
                            .symbolRenderingMode(.multicolor)
                    })
                }
            } else {
                ImageViewer(image: loaded)
            }
        }
    }
}

struct ImageViewer: View {
    let image: CachedRemoteImage.LoadedImage
    
    var body: some View {
        QuickLookPresentor(image: image.uiImage, imageURL: image.fileURL)
            .scaledToFit()
    }
}

#Preview {
    NavigationStack {
        List {
            CachedRemoteImage(URL(string: "https://danxi.fduhole.com/assets/app.webp")!)
                .frame(maxHeight: 300)
        }
    }
}
