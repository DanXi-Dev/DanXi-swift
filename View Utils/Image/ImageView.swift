import SwiftUI
import SensitiveContentAnalysis
import Disk

struct ImageView: View {
    enum LoadingStatus {
        case loading
        case error(error: Error)
        case loaded(image: LoadedImage)
    }
    
    @State private var showSensitive = false
    @State private var loadingStatus: LoadingStatus = .loading
    private let url: URL
    
    init(_ url: URL) {
        self.url = url
    }
    
    func load() {
        Task(priority: .medium) {
            await MainActor.run { loadingStatus = .loading }
            do {
                let loadedImage = try await loadImage(url)
                await MainActor.run { loadingStatus = .loaded(image: loadedImage) }
            } catch {
                await MainActor.run { loadingStatus = .error(error: error) }
            }
        }
    }
    
    var body: some View {
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
                if loadedImage.isSensitive && !showSensitive {
                    Button {
                        withAnimation {
                            showSensitive = true
                        }
                    } label: {
                        ZStack(alignment: .center) {
                            loadedImage.image
                                .scaledToFit()
                                .overlay(.ultraThickMaterial)
                                .clipped()
                                .allowsHitTesting(false)
                            
                            Image(systemName: "eye.trianglebadge.exclamationmark")
                                .font(.largeTitle)
                                .foregroundColor(.primary)
                                .symbolRenderingMode(.multicolor)
                        }
                    }
                } else {
                    ImageBrowser(image: loadedImage.uiImage, imageURL: loadedImage.fileURL)
                        .scaledToFit()
                }
            }
            Spacer()
        }
        .frame(maxHeight: 300)
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
