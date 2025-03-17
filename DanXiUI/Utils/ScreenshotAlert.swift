import SwiftUI

extension View {
    func screenshotAlert() -> some View {
        ScreenshotAlert(content: self)
    }
}

struct ScreenshotAlert<Content: View>: View {
    let content: Content
    @AppStorage("screenshot-alert") var active = true
    @StateObject private var model = ScreenshotAlertModel()
    private let screenshotPublisher = NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
    
    var body: some View {
        if active {
            content
                .background {
                    ScreenshotAlertPresentor()
                        .environmentObject(model)
                }
                .onReceive(screenshotPublisher) { _ in
                    model.presentAlert()
                }
        } else {
            content
        }
    }
}

@MainActor
class ScreenshotAlertModel: ObservableObject {
    weak var uiView: UIView? = nil
    
    func presentAlert() {
        let alertController = UIAlertController(title: String(localized: "Screenshot Detected", bundle: .module), message: String(localized: "Screenshot Alert Content", bundle: .module), preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: String(localized: "OK", bundle: .module), style: .default) { _ in
            // do nothing
        }
        alertController.addAction(defaultAction)
        
        guard let rootViewController = uiView?.window?.rootViewController,
              rootViewController.presentedViewController == nil else {
            return
        }
        rootViewController.present(alertController, animated: true)
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
