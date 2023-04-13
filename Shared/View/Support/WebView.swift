import SwiftUI
import WebKit

struct WebViewWrapper: View {
    let request: URLRequest
    
    init(_ request: URLRequest) {
        self.request = request
    }
    
    var body: some View {
        GeometryReader { proxy in
            WebView(frame: proxy.frame(in: .local), request: request)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea(.all)
    }
}

struct WebView: UIViewRepresentable {
    let frame: CGRect
    let request: URLRequest
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.processPool = WKProcessPool()
        let cookies = HTTPCookieStorage.shared.cookies ?? [HTTPCookie]()
        cookies.forEach { config.websiteDataStore.httpCookieStore.setCookie($0, completionHandler: nil) }
        
        let webView = WKWebView(frame: frame, configuration: config)
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.load(request)
    }
}


