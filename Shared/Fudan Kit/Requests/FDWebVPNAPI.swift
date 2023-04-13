import Foundation

struct FDWebVPNAPI {
    static func login() async throws {
        let loginURL = URL(string: "https://webvpn.fudan.edu.cn/login?cas_login=true")!
        _ = try await FDAuthAPI.auth(url: loginURL)
    }
}
