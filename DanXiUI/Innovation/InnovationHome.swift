import SwiftUI
import WebKit

public struct InnovationHomePage: UIViewRepresentable {
    public init() { }
    
    public func makeUIView(context: Context) -> WKWebView {
        let webview = WKWebView()
        return webview
    }
    
    public func updateUIView(_ webview: WKWebView, context: Context) {
        // do nothing
    }
}
