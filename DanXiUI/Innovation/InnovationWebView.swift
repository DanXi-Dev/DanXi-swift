import SwiftUI
import WebKit
import DanXiKit

// MARK: - UI

struct InnovationWebView: UIViewRepresentable {
    @EnvironmentObject private var model: WebViewModel
    
    typealias Coordinator = WebViewModel
    
    let url: URL
    let frame: CGRect
    
    func makeCoordinator() -> WebViewModel {
        model
    }
    
    private func setupConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        
        if let token = CredentialStore.shared.token {
            let accessCookie = HTTPCookie(properties: [
                .domain: "danta.fudan.edu.cn",
                .path: "/",
                .name: "access",
                .value: token.access,
                .version: 1,
            ])
            
            let refreshCookie = HTTPCookie(properties: [
                .domain: "danta.fudan.edu.cn",
                .path: "/",
                .name: "refresh",
                .value: token.refresh,
                .version: 1,
            ])
            
            if let accessCookie, let refreshCookie {
                configuration.websiteDataStore.httpCookieStore.setCookie(accessCookie)
                configuration.websiteDataStore.httpCookieStore.setCookie(refreshCookie)
            }
        }
        
        return configuration
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = setupConfiguration()
        let webview = WKWebView(frame: frame, configuration: configuration)
        let request = URLRequest(url: url)
        webview.allowsBackForwardNavigationGestures = true
        webview.load(request)
        webview.navigationDelegate = context.coordinator
        webview.uiDelegate = context.coordinator
        context.coordinator.webview = webview
        return webview
    }
    
    func updateUIView(_ webview: WKWebView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.canGoBack = webview.canGoBack
            context.coordinator.canGoForward = webview.canGoForward
        }
    }
}

// MARK: - Data

enum WebViewLoadingStatus {
    case loading
    case completed
    case failed(error: Error)
}

class WebViewModel: NSObject, ObservableObject {
    @Published var externalURL: URL? = nil
    @Published var loadingStatus = WebViewLoadingStatus.loading
    @Published var canGoBack = false
    @Published var canGoForward = false
    weak var webview: WKWebView! = nil
    
    func goBack() {
        webview.goBack()
    }
    
    func goForward() {
        webview.goForward()
    }
    
    func reload() {
        loadingStatus = .loading
        webview.reload()
    }
}

extension WebViewModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingStatus = .completed
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        loadingStatus = .failed(error: error)
    }
}

extension WebViewModel: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url {
            #if targetEnvironment(macCatalyst)
            UIApplication.shared.open(url)
            #else
            externalURL = url
            #endif
        }
        
        return nil
    }
    
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping @MainActor (WKPermissionDecision) -> Void
    ) {
        decisionHandler(.deny)
    }
}
