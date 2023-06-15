import SwiftUI

struct FDCoursePage: View {
    var body: some View {
        AsyncContentView { () -> URL in
            try await FDWebVPNAPI.login()
            return URL(string: "https://webvpn.fudan.edu.cn/http/77726476706e69737468656265737421a1a70fca737e39032e46df/")!
        } content: { url in
            WebViewWrapper(URLRequest(url: url))
                .navigationTitle("Online Course Table")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
