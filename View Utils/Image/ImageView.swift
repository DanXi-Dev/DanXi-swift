#if !os(watchOS)
import SwiftUI
import Disk

public struct ImageView: View {
    @Environment(\.supportImageBrowsing) private var supportImageBrowsing
    
    enum LoadingStatus {
        case loading
        case error(error: Error)
        case loaded(image: LoadedImage)
    }
    
    @State private var showSensitive = false
    @State private var loadingStatus: LoadingStatus = .loading
    private let url: URL
    private let proxiedURL: URL?
    
    public init(_ url: URL, proxiedURL: URL? = nil) {
        self.url = url
        self.proxiedURL = proxiedURL
    }
    
    func load() {
        Task(priority: .medium) {
            await MainActor.run { loadingStatus = .loading }
            do {
                let loadedImage = try await loadImage(url, proxiedURL: proxiedURL)
                await MainActor.run { loadingStatus = .loaded(image: loadedImage) }
            } catch {
                await MainActor.run { loadingStatus = .error(error: error) }
            }
        }
    }
    
    public var body: some View {
        HStack {
            Spacer()
            switch loadingStatus {
            case .loading:
                ProgressView()
                    .frame(width: 300, height: 300)
                    .background(Color.gray.opacity(0.2))
                    .onAppear {
                        load()
                    }
            case .error:
                Button(action: load) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .frame(width: 300, height: 300)
                        .background(Color.gray.opacity(0.2))
                }
            case .loaded(let loadedImage):
                if supportImageBrowsing {
                    ImageBrowser(image: loadedImage.uiImage, fileURL: loadedImage.fileURL, remoteURL: url)
                        .scaledToFit()
                } else {
                    loadedImage.image
                        .resizable()
                        .scaledToFit()
                }
            }
            Spacer()
        }
        .frame(maxHeight: 300)
    }
}

public struct SupportImageBrowsingKey: EnvironmentKey {
    static public let defaultValue = false
}

extension EnvironmentValues {
    public var supportImageBrowsing: Bool {
        get { self[SupportImageBrowsingKey.self] }
        set { self[SupportImageBrowsingKey.self] = newValue }
    }
}

#Preview {
    NavigationStack {
        List {
            ImageView(URL(string: "https://danxi.fduhole.com/assets/app.webp")!)
                .frame(maxHeight: 300)
        }
    }
}
#endif
