import SwiftUI
import BetterSafariView

extension View {
    /// Use safari controller to open links inside this view
    /// - Parameter respectSettings: Respect the settings of whether to open links in safari controller. Default `false`.
    func useSafariController(respectSettings: Bool = false) -> some View {
        self.modifier(SafariViewModifier(respectSettings: respectSettings))
    }
}

struct SafariViewModifier: ViewModifier {
    let respectSettings: Bool
    
    func body(content: Content) -> some View {
        SafariWrapper(respectSettings: respectSettings) {
            content
        }
    }
}

private struct SafariWrapper<Content: View>: View {
    @ObservedObject private var settings = ForumSettings.shared
    @State private var safariURL: URL? = nil
    
    private let respectSettings: Bool
    private let content: () -> Content
    
    private var shouldOpenInBrowser: Bool {
        if respectSettings {
            !settings.inAppBrowser
        } else {
            false
        }
    }
    
    init(respectSettings: Bool, content: @escaping () -> Content) {
        self.respectSettings = respectSettings
        self.content = content
    }
    
    var body: some View {
        content()
            #if !targetEnvironment(macCatalyst)
            .environment(\.openURL, OpenURLAction { url in
                if shouldOpenInBrowser {
                    UIApplication.shared.open(url)
                } else {
                    safariURL = url
                }
                return .handled
            })
            .safariView(item: $safariURL) { link in
                SafariView(url: link)
            }
            #endif
    }
}
