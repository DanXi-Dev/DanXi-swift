import SwiftUI
import QuickLook

struct QuickLookPresentor: UIViewRepresentable {
    let image: UIImage
    let imageURL: URL
    
    func makeCoordinator() -> Coordinator {
        Coordinator(image: image, imageURL: imageURL)
    }
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.present))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGestureRecognizer)
        
        let interaction = UIContextMenuInteraction(delegate: context.coordinator)
        imageView.addInteraction(interaction)
        
        context.coordinator.uiView = imageView
        
        return imageView
    }
    
    func updateUIView(_ imageView: UIImageView, context: Context) {
        context.coordinator.uiView = imageView
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate, UIContextMenuInteractionDelegate {
        init(image: UIImage, imageURL: URL) {
            self.image = image
            self.imageURL = imageURL
        }
        
        let imageURL: URL
        let image: UIImage
        var uiView: UIView?
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> any QLPreviewItem {
            PreviewItem(imageURL)
        }
        
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
            uiView
        }
        
        
        
        @objc func present() {
            let previewController = QLPreviewController()
            previewController.dataSource = self
            previewController.delegate = self
            uiView?.window?.farthestPresentedViewController?.present(previewController, animated: true)
            previewController.currentPreviewItemIndex = 1
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
            return UIContextMenuConfiguration(identifier: nil) {
                let previewController = QLPreviewController()
                previewController.dataSource = self
                previewController.delegate = self
                return previewController
            } actionProvider: { suggestedActions in
                let save = UIAction(title: String(localized: "Save to Album"), image: UIImage(systemName: "square.and.arrow.down")) { action in
                    UIImageWriteToSavedPhotosAlbum(self.image, nil, nil, nil)
                }

                // Create and return a UIMenu with all of the actions as children
                return UIMenu(title: "", children: [save])
            }
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
            animator.addCompletion {
                let previewController = QLPreviewController()
                previewController.dataSource = self
                previewController.delegate = self
                self.uiView?.window?.farthestPresentedViewController?.show(previewController, sender: self)
            }
        }
    }
    
    class PreviewItem: NSObject, QLPreviewItem {
        let previewItemURL: URL?
        var previewItemTitle: String? {
            ""
        }
        
        init(_ url: URL?) {
            self.previewItemURL = url
        }
    }
}

extension UIWindow {
    /// The view controller that was presented modally on top of the window.
    var farthestPresentedViewController: UIViewController? {
        guard let rootViewController = rootViewController else { return nil }
        return Array(sequence(first: rootViewController, next: \.presentedViewController)).last
    }
}