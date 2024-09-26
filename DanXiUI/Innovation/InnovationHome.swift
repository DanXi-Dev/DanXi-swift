import SwiftUI
import DanXiKit
import WebKit

public struct InnovationHomePage: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    public init() { }
    
    public var body: some View {
        if horizontalSizeClass == .compact {
            GeometryReader { proxy in
                WebView(frame: proxy.frame(in: .local))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .toolbar(.hidden, for: .navigationBar)
        } else {
            GeometryReader { proxy in
                WebView(frame: proxy.frame(in: .local))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea(.all)
            .navigationBarHidden(true)
        }
    }
}

private struct WebView: UIViewRepresentable {
    let frame: CGRect
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.processPool = WKProcessPool()
        
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
                config.websiteDataStore.httpCookieStore.setCookie(accessCookie)
                config.websiteDataStore.httpCookieStore.setCookie(refreshCookie)
            }
        }
        
        let webView = WKWebView(frame: frame, configuration: config)
        let url = URL(string: "https://danta.fudan.edu.cn/lobby/1")!
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // do nothing
    }
}
