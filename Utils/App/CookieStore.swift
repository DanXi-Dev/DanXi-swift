import Foundation

/// Persists Fudan / WebVPN cookies across app launches.
///
/// iOS drops session cookies (the WebVPN ticket is one) when the app quits, so we
/// snapshot them ourselves on background and restore them on the next launch.
public enum CookieStore {
    private static let storageKey = "persisted-fudan-cookies"
    private static let domainSuffix = "fudan.edu.cn"

    /// Snapshot the current Fudan cookies to disk. Call when entering the background.
    public static func save() {
        let cookies = (HTTPCookieStorage.shared.cookies ?? []).filter { $0.domain.contains(domainSuffix) }
        let encoded: [[String: String]] = cookies.map { cookie in
            var dict = [
                "name": cookie.name,
                "value": cookie.value,
                "domain": cookie.domain,
                "path": cookie.path,
            ]
            if let expires = cookie.expiresDate { dict["expires"] = String(expires.timeIntervalSince1970) }
            if cookie.isSecure { dict["secure"] = "1" }
            return dict
        }
        guard let data = try? JSONEncoder().encode(encoded) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    /// Restore persisted cookies into shared storage. Call once, early on launch,
    /// before any authenticated request is made.
    public static func restore() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([[String: String]].self, from: data) else { return }
        for dict in decoded {
            guard let name = dict["name"], let value = dict["value"],
                  let domain = dict["domain"], let path = dict["path"] else { continue }
            var properties: [HTTPCookiePropertyKey: Any] = [
                .name: name,
                .value: value,
                .domain: domain,
                .path: path,
            ]
            if let expires = dict["expires"], let interval = TimeInterval(expires) {
                properties[.expires] = Date(timeIntervalSince1970: interval)
            }
            if dict["secure"] == "1" { properties[.secure] = "TRUE" }
            if let cookie = HTTPCookie(properties: properties) {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
    }

    /// Drop the persisted cookies (e.g. on logout / account switch).
    public static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
