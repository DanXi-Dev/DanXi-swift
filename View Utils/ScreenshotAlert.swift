import SwiftUI

extension View {
    public func screenshotAlert() -> some View {
        ScreenshotAlert(content: self)
    }
}

struct ScreenshotAlert<Content: View>: View {
    let content: Content
    private let screenshotPublisher = NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
    @State private var count = 0
    
    var body: some View {
        content
            .background {
                ScreenshotAlertPresentor(count: count, title: String(localized: "Screenshot Detected"), message: String(localized: "Screenshot Alert Content"))
            }
            .onReceive(screenshotPublisher) { _ in
                count += 1
            }
    }
}

struct ScreenshotAlertPresentor: UIViewRepresentable {
    let count: Int
    let title: String
    let message: String
    
    func makeUIView(context: Context) -> UIView {
        UIView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard count > 0 else { return }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: String(localized: "OK"), style: .default) { _ in
            // do nothing
        }
        alertController.addAction(defaultAction)
        uiView.window?.farthestPresentedViewController?.present(alertController, animated: true)
    }
}
