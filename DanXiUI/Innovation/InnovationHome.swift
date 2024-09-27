import SwiftUI
import DanXiKit
import WebKit

public struct InnovationHomePage: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var model = WebViewModel()
    
    public init() { }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                WebView(frame: proxy.frame(in: .local))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .environmentObject(model)
                    .opacity(model.loadingComplete ? 1 : 0)
                
                if !model.loadingComplete {
                    VStack {
                        ProgressView()
                        Text("Loading", bundle: .module)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let error = model.loadingError {
                    VStack {
                        Text("Loading Failed", bundle: .module)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(error.localizedDescription)
                            .font(.callout)
                            .padding(.bottom)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            model.reload()
                        } label: {
                            Text("Retry", bundle: .module)
                        }
                        .foregroundStyle(Color.accentColor)
                    }
                    .padding()
                }
            }
        }
        .ignoresSafeArea(.all)
        .toolbar {
            Button {
                model.goBack()
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(!model.canGoBack)
            
            Button {
                model.goForward()
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(!model.canGoForward)
            
            Button {
                model.reload()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
        }
    }
}

private class WebViewModel: NSObject, ObservableObject {
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var loadingComplete = false
    @Published var loadingError: Error? = nil
    
    weak var webview: WKWebView? = nil
    
    func goBack() {
        webview?.goBack()
    }
    
    func goForward() {
        webview?.goForward()
    }
    
    func reload() {
        loadingComplete = false
        loadingError = nil
        
        webview?.reload()
    }
}

extension WebViewModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingComplete = true
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        loadingError = error
        loadingComplete = true
    }
}

private struct WebView: UIViewRepresentable {
    @EnvironmentObject private var model: WebViewModel
    
    typealias Coordinator = WebViewModel
    
    let frame: CGRect
    
    func makeCoordinator() -> WebViewModel {
        model
    }
    
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
        webView.allowsBackForwardNavigationGestures = true
        webView.load(request)
        webView.navigationDelegate = context.coordinator
        context.coordinator.webview = webView
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.canGoBack = webView.canGoBack
            context.coordinator.canGoForward = webView.canGoForward
        }
    }
}
