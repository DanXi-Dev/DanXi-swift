import Foundation

/// Preserves WebVPN session cookies across app launches.
public enum WebVPNCookieStore {
    private static let domain = "webvpn.fudan.edu.cn"
    private static let storageKey = "webvpn-cookies"

    public static func save() {
        let cookies = (HTTPCookieStorage.shared.cookies ?? [])
            .filter { $0.domain == domain || $0.domain == ".\(domain)" }
            .map(PersistedCookie.init)

        if let data = try? JSONEncoder().encode(cookies) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    public static func restore() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let cookies = try? JSONDecoder().decode([PersistedCookie].self, from: data) else {
            return
        }

        cookies.compactMap(\.cookie).forEach(HTTPCookieStorage.shared.setCookie)
    }

    public static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

private struct PersistedCookie: Codable {
    let name: String
    let value: String
    let domain: String
    let path: String
    let expiresDate: Date?
    let isSecure: Bool

    init(_ cookie: HTTPCookie) {
        name = cookie.name
        value = cookie.value
        domain = cookie.domain
        path = cookie.path
        expiresDate = cookie.expiresDate
        isSecure = cookie.isSecure
    }

    var cookie: HTTPCookie? {
        var properties: [HTTPCookiePropertyKey: Any] = [
            .name: name,
            .value: value,
            .domain: domain,
            .path: path,
        ]
        if let expiresDate {
            properties[.expires] = expiresDate
        }
        if isSecure {
            properties[.secure] = "TRUE"
        }
        return HTTPCookie(properties: properties)
    }
}
