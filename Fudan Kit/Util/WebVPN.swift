import Foundation
import Utils
import SwiftSoup

public func authenticateWebVPN() async throws {
    let loginURL = URL(string: "https://id.fudan.edu.cn/idp/authCenter/authenticate?service=https%3A%2F%2Fwebvpn.fudan.edu.cn%2Flogin%3Fcas_login%3Dtrue")!
    let request = constructRequest(loginURL)
    let firstResult = try await URLSession.shared.data(for: request)
    
    if let ticket = try? retrieveTicket(firstResult) {
        try await performLogin(ticket: ticket)
        return
    }
    
    let authenticationURL = URL(string: "https://id.fudan.edu.cn/idp/thirdAuth/cas")!
    let centerURL = try await AuthenticationAPI.authenticateForURL(authenticationURL)
    
    let secondResult = try await URLSession.shared.data(from: centerURL)
    guard let ticket = try? retrieveTicket(secondResult) else {
        throw LocatableError()
    }
    try await performLogin(ticket: ticket)
}

private func retrieveTicket(_ tuple: (Data, URLResponse)) throws -> String? {
    let (data, response) = tuple
    guard let url = response.url, url.host == "id.fudan.edu.cn" else { return nil }
    
    let element = try decodeHTMLElement(data, selector: "#ticket")
    let ticket = try element.attr("value")
    return ticket
}

private func performLogin(ticket: String) async throws {
    var component = URLComponents(string: "https://webvpn.fudan.edu.cn/login")!
    component.queryItems = [
        URLQueryItem(name: "cas_login", value: "true"),
        URLQueryItem(name: "ticket", value: ticket)
    ]
    _ = try await URLSession.shared.data(from: component.url!)
}
