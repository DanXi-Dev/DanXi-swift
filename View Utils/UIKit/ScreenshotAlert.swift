import SwiftUI

extension View {
    public func screenshotAlert() -> some View {
        ScreenshotAlert(content: self)
    }
}

struct ScreenshotAlert<Content: View>: View {
    let content: Content
    @StateObject private var model = ScreenshotAlertModel()
    private let screenshotPublisher = NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
    
    var body: some View {
        content
            .background {
                ScreenshotAlertPresentor()
                    .environmentObject(model)
            }
            .onReceive(screenshotPublisher) { _ in
                model.presentAlert()
            }
    }
}

class ScreenshotAlertModel: ObservableObject {
    weak var uiView: UIView? = nil
    
    func presentAlert() {
        let alertController = UIAlertController(title: String(localized: "Screenshot Detected"), message: String(localized: "Screenshot Alert Content"), preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: String(localized: "OK"), style: .default) { _ in
            // do nothing
        }
        alertController.addAction(defaultAction)
        uiView?.window?.farthestPresentedViewController?.present(alertController, animated: true)
    }
}

struct ScreenshotAlertPresentor: UIViewRepresentable {
    @EnvironmentObject private var model: ScreenshotAlertModel
    
    func makeUIView(context: Context) -> UIView {
        let uiView = UIView()
        model.uiView = uiView
        return uiView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // do nothing
    }
}
