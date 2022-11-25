import Foundation
import SwiftSoup

let UIS_URL = "https://uis.fudan.edu.cn"

struct FudanAuthRequests {
    static func login(_ username: String, _ password: String) async throws {
        if try await needCaptcha(username: username) {
            throw FudanError.needCaptcha
        }
        
        // make request to server
        let authUrl = URL(string: UIS_URL + "/authserver/login")!
        var request = URLRequest(url: authUrl)
        request.setUserAgent()
        let (loginFormData, _) = try await URLSession.shared.data(for: request)
        let authRequest = try prepareAuthRequest(authURL: authUrl, formData: loginFormData,
                                                 username: username, password: password)
        let (_, response) = try await URLSession.shared.data(for: authRequest)
        if response.url?.absoluteString != "https://uis.fudan.edu.cn/authserver/index.do" {
            throw HTTPError.unauthorized
        }
    }
    
    static func auth(url: URL) async throws -> Data {
        guard let username = CredentialStore.shared.username,
              let password = CredentialStore.shared.password else {
            throw FudanError.credentialNotFound
        }
        
        var components = URLComponents(string: UIS_URL + "/authserver/login")!
        components.queryItems = [URLQueryItem(name: "service", value: url.absoluteString)]
        var request = URLRequest(url: components.url!)
        request.setUserAgent()
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // if local cookie is not expired, the response will be returned directly. otherwise, this will redirect to Fudan UIS page.
        guard response.url?.host == "uis.fudan.edu.cn" else {
            return data
        }
        let authRequest = try prepareAuthRequest(authURL: components.url!, formData: data,
                                                 username: username, password: password)
        let (newData, newResponse) = try await URLSession.shared.data(for: authRequest)
        guard newResponse.url?.host != "uis.fudan.edu.cn" else {
            throw HTTPError.unauthorized
        }
        return newData
    }
    
    static func prepareAuthRequest(authURL: URL, formData: Data,
                                    username: String, password: String) throws -> URLRequest {
        var loginForm = [
            URLQueryItem(name: "username", value: username),
            URLQueryItem(name: "password", value: password)
        ]
        
        guard let htmlText = String(data: formData, encoding: String.Encoding.utf8) else {
            throw NetworkError.invalidResponse
        }
        
        do {
            let doc = try SwiftSoup.parse(htmlText)
            for element in try doc.select("input") {
                if try element.attr("type") == "hidden" {
                    loginForm.append(URLQueryItem(name: try element.attr("name"),
                                                  value: try element.attr("value")))
                }
            }
        } catch {
            throw NetworkError.invalidResponse
        }
        
        let requestHeaders = ["Content-Type" : "application/x-www-form-urlencoded"]
        var requestBodyComponents = URLComponents()
        requestBodyComponents.queryItems = loginForm
        var request = URLRequest(url: authURL)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = requestHeaders
        request.setUserAgent()
        request.httpBody = requestBodyComponents.query?.data(using: .ascii)
        
        return request
    }
    
    static func needCaptcha(username: String) async throws -> Bool {
        var component = URLComponents(string: UIS_URL + "/authserver/needCaptcha.html")!
        component.queryItems = [URLQueryItem(name: "username", value: username)]
        var request = URLRequest(url: component.url!)
        request.setUserAgent()
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let result = String(data: data, encoding: String.Encoding.ascii) else {
            throw NetworkError.invalidResponse
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines) != "false"
    }
}
