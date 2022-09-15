import SwiftUI
import UIKit

struct PreviewContextView<Preview: View>: UIViewRepresentable {

    let preview: Preview?
    let preferredContentSize: CGSize?
    let actions: [UIAction]
    let isPreviewOnly: Bool
    @Binding var isActive: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.addInteraction(
            UIContextMenuInteraction(
                delegate: context.coordinator
            )
        )
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIContextMenuInteractionDelegate {
        
        private let view: PreviewContextView<Preview>
        
        init(_ view: PreviewContextView<Preview>) {
            self.view = view
        }
        
        func contextMenuInteraction(
            _ interaction: UIContextMenuInteraction,
            configurationForMenuAtLocation location: CGPoint
        ) -> UIContextMenuConfiguration? {
            UIContextMenuConfiguration(
                identifier: nil,
                previewProvider: {
                    let hostingController = UIHostingController(rootView: self.view.preview)
                    
                    if let preferredContentSize = self.view.preferredContentSize {
                        hostingController.preferredContentSize = preferredContentSize
                    }
                    
                    return hostingController
                }, actionProvider: { _ in
                    UIMenu(title: "", children: self.view.actions)
                }
            )
        }
        
        func contextMenuInteraction(
            _ interaction: UIContextMenuInteraction,
            willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
            animator: UIContextMenuInteractionCommitAnimating
        ) {
            guard !view.isPreviewOnly else { return }
            
            view.isActive = true
        }
    }
}
