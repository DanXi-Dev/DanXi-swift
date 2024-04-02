import SwiftUI
import Disk

public struct CachedRemoteImage: View {
    enum LoadingStatus {
        case loading
        case error(error: Error)
        case loaded(image: LoadedImage)
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
    
    func loadImage() {
        Task {
            do {
                await setLoadingStatus(.loading)
                let name = url.absoluteString.data(using: .utf8)!.base64EncodedString()
                let filename = "cachedimages/\(name).jpg"
                
                // retrive cache from disk
                if let fileURL = try? Disk.url(for: filename, in: .caches),
                   let uiImage = try? Disk.retrieve(filename, from: .caches, as: UIImage.self) {
                    let image = Image(uiImage: uiImage)
                    let loadedImage = LoadedImage(image: image, uiImage: uiImage, fileURL: fileURL)
                    await setLoadingStatus(.loaded(image: loadedImage))
                    return
                }
                
                // download from internet
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let uiImage = UIImage(data: data) else { throw URLError(.badServerResponse) }
                let image = Image(uiImage: uiImage)
                try Disk.save(uiImage, to: .caches, as: filename)
                let fileURL = try Disk.url(for: filename, in: .caches)
                let loadedImage = LoadedImage(image: image, uiImage: uiImage, fileURL: fileURL)
                await setLoadingStatus(.loaded(image: loadedImage))
            } catch {
                loadingStatus = .error(error: error)
            }
        }
    }
    
    public var body: some View {
        switch loadingStatus {
        case .loading:
            ProgressView()
                .frame(width: 200, height: 150)
                .background(Color.gray.opacity(0.2))
                .onAppear {
                    loadImage()
                }
        case .error:
            Button(action: loadImage) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .frame(width: 200, height: 150)
                    .background(Color.gray.opacity(0.2))
            }
        case .loaded(let loaded):
            QuickLookPresentor(image: loaded.uiImage, imageURL: loaded.fileURL)
        }
    }
}

#Preview {
    NavigationStack {
        List {
            CachedRemoteImage(URL(string: "https://danxi.fduhole.com/assets/app.webp")!)
        }
    }
}
