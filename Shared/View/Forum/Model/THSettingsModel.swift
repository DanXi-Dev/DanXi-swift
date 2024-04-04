import SwiftUI
import PhotosUI
import Disk

@MainActor
class THSettings: ObservableObject {
    static let shared = THSettings()
    
    private init() {
        if let uiImage = try? Disk.retrieve("fduhole/background-image.png", from: .applicationSupport, as: UIImage.self) {
            backgroundImage = Image(uiImage: uiImage)
        }
    }
    
    enum SensitiveContentSetting: Int {
        case fold = 1, show, hide
    }
    
    @AppStorage("sensitive-content") var sensitiveContent = SensitiveContentSetting.fold
    @AppStorage("blocked-tags") var blockedTags: [String] = []
    @AppStorage("show-last-floor") var showLastFloor: Bool = false
    @AppStorage("blocked-holes") var blockedHoles: [Int] = []
    @AppStorage("screenshot-alert") var screenshotAlert = true
    @AppStorage("show-activity") var showBanners = true
    let watermarkOpacity = 0.011
    @Published var backgroundImage: Image? = nil
    
    func setBackgroundImage(_ item: PhotosPickerItem?) {
        guard let item = item else {
            backgroundImage = nil
            try? Disk.remove("fduhole/background-image.png", from: .applicationSupport)
            return
        }
        
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else { return }
                guard let uiImage = UIImage(data: data) else { return }
                try Disk.save(uiImage, to: .applicationSupport, as: "fduhole/background-image.png")
                backgroundImage = Image(uiImage: uiImage)
            } catch {
                
            }
        }
    }
}
