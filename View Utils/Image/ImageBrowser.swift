import SwiftUI
import QuickLook
import Disk

public struct AllImageURLKey: EnvironmentKey {
    public static let defaultValue: [URL] = []
}

extension EnvironmentValues {
    public var allImageURL: [URL] {
        get { self[AllImageURLKey.self] }
        set { self[AllImageURLKey.self] = newValue }
    }
}

struct ImageBrowser: UIViewRepresentable {
    typealias Coordinator = ImageBrowserCoordinator
    
    @Environment(\.allImageURL) private var allImageURL
    
    let image: UIImage
    let fileURL: URL
    let remoteURL: URL
    
    func makeCoordinator() -> Coordinator {
        Coordinator(image: image, fileURL: fileURL, remoteURL: remoteURL)
    }
    
    func makeUIView(context: Context) -> UIView {
        let imageView = UIImageView(image: image)
        
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.present))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
        
        let interaction = UIContextMenuInteraction(delegate: context.coordinator)
        imageView.addInteraction(interaction)
        
        let dragInteraction = UIDragInteraction(delegate: context.coordinator)
        imageView.addInteraction(dragInteraction)
        
        context.coordinator.uiView = imageView
        context.coordinator.allRemoteURL = allImageURL
        
        return imageView
    }
    
    func updateUIView(_ imageView: UIView, context: Context) {
        context.coordinator.uiView = imageView
        context.coordinator.allRemoteURL = allImageURL
    }
}

@MainActor
class ImageBrowserCoordinator: NSObject {
    init(image: UIImage, fileURL: URL, remoteURL: URL) {
        self.image = image
        self.fileURL = fileURL
        self.remoteURL = remoteURL
        
        self.allRemoteURL = [remoteURL]
        self.localURLMap = [remoteURL: PreviewItem(fileURL)]
    }
    
    let image: UIImage
    let fileURL: URL
    let remoteURL: URL
    
    var uiView: UIView?
    
    var allRemoteURL: [URL]
    var localURLMap: [URL: PreviewItem]
    
    var initialIndex: Int {
        allRemoteURL.firstIndex(of: remoteURL) ?? 1
    }
    
    @objc func present() {
        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewController.delegate = self
        uiView?.window?.farthestPresentedViewController?.present(previewController, animated: true)
        previewController.currentPreviewItemIndex = initialIndex
    }
}

extension ImageBrowserCoordinator: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        max(allRemoteURL.count, 1)
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> any QLPreviewItem {
        if allRemoteURL.isEmpty {
            return PreviewItem(fileURL)
        }
        let remoteURL = allRemoteURL[index]
        if let previewItem = localURLMap[remoteURL] {
            return previewItem
        }
        
        if let fileURL = DiskImageCache.shared.getImageURL(remoteURL) {
            let previewItem = PreviewItem(fileURL)
            localURLMap[remoteURL] = previewItem
            return previewItem
        }
        
        let previewItem = PreviewItem(nil)
        localURLMap[remoteURL] = previewItem // prevent other call to repeatedly load the same image
        Task(priority: .medium) {
            let loadedImage = try await loadImage(remoteURL)
            let previewItem = PreviewItem(loadedImage.fileURL)
            localURLMap[remoteURL] = previewItem
            await MainActor.run {
                controller.refreshCurrentPreviewItem()
            }
        }
        return previewItem
    }
}

extension ImageBrowserCoordinator: @preconcurrency QLPreviewControllerDelegate {
    func previewController(
        _ controller: QLPreviewController,
        editingModeFor previewItem: any QLPreviewItem
    ) -> QLPreviewItemEditingMode {
        .disabled
    }
    
    func previewController(
        _ controller: QLPreviewController,
        transitionViewFor item: any QLPreviewItem
    ) -> UIView? {
        // if the presenting image is different from the base image, it should not scale back.
        guard item.previewItemURL == fileURL else {
            return nil
        }
        return uiView
    }
}

extension ImageBrowserCoordinator: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil) {
            let previewController = QLPreviewController()
            previewController.dataSource = self
            previewController.delegate = self
            previewController.currentPreviewItemIndex = self.initialIndex
            return previewController
        } actionProvider: { suggestedActions in
            let save = UIAction(title: String(localized: "Save to Album", bundle: .module), image: UIImage(systemName: "square.and.arrow.down")) { action in
                UIImageWriteToSavedPhotosAlbum(self.image, nil, nil, nil)
            }
            
            let copy = UIAction(title: String(localized: "Copy", bundle: .module), image: UIImage(systemName: "doc.on.doc")) { action in
                UIPasteboard.general.image = self.image
            }
            
            // Create and return a UIMenu with all of the actions as children
            return UIMenu(title: "", children: [copy, save])
        }
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion {
            let previewController = QLPreviewController()
            previewController.dataSource = self
            previewController.delegate = self
            previewController.currentPreviewItemIndex = self.initialIndex
            self.uiView?.window?.farthestPresentedViewController?.show(previewController, sender: self)
        }
    }
}

extension ImageBrowserCoordinator: UIDragInteractionDelegate {
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        let image = self.image
        let provider = NSItemProvider(object: image)
        let item = UIDragItem(itemProvider: provider)
        item.localObject = image
        return [item]
    }
}

class PreviewItem: NSObject, QLPreviewItem {
    let previewItemURL: URL?
    var previewItemTitle: String? {
        String(localized: "Photo", bundle: .module)
    }
    
    init(_ url: URL?) {
        self.previewItemURL = url
    }
}

extension UIWindow {
    /// The view controller that was presented modally on top of the window.
    var farthestPresentedViewController: UIViewController? {
        guard let rootViewController = rootViewController else { return nil }
        return Array(sequence(first: rootViewController, next: \.presentedViewController)).last
    }
}
