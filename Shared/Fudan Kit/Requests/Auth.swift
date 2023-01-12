import Foundation
import SwiftSoup

let UIS_URL = "https://uis.fudan.edu.cn"

struct FudanAuthRequests {
    static func login(_ username: String, _ password: String) async throws {
        if try await needCaptcha(username: username) {
            throw FDError.needCaptcha
        }
        
        // make request to server
        let authUrl = URL(string: UIS_URL + "/authserver/login")!
        let request = prepareRequest(authUrl)
        let (loginFormData, _) = try await URLSession.shared.data(for: request)
        let authRequest = try prepareAuthRequest(authURL: authUrl, formData: loginFormData,
                                                 username: username, password: password)
        let (_, response) = try await sendRequest(authRequest)
        if response.url?.absoluteString != "https://uis.fudan.edu.cn/authserver/index.do" {
            throw HTTPError.unauthorized
        }
    }
    
    static func auth(url: URL) async throws -> Data {
        guard let username = FDSecStore.shared.username,
              let password = FDSecStore.shared.password else {
            throw FDError.credentialNotFound
        }
        
        var components = URLComponents(string: UIS_URL + "/authserver/login")!
        components.queryItems = [URLQueryItem(name: "service", value: url.absoluteString)]
        let request = prepareRequest(components.url!)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // if local cookie is not expired, the response will be returned directly. otherwise, this will redirect to Fudan UIS page.
        guard response.url?.host == "uis.fudan.edu.cn" else {
            return data
        }
        let authRequest = try prepareAuthRequest(authURL: components.url!, formData: data,
                                                 username: username, password: password)
        let (newData, newResponse) = try await sendRequest(authRequest)
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
        
        do {
            let doc = try processHTMLData(formData)
            for element in try doc.select("input") {
                if try element.attr("type") == "hidden" {
                    loginForm.append(URLQueryItem(name: try element.attr("name"),
                                                  value: try element.attr("value")))
                }
            }
        } catch {
            throw NetworkError.invalidResponse
        }
        
        return prepareFormRequest(authURL, form: loginForm)
    }
    
    static func needCaptcha(username: String) async throws -> Bool {
        var component = URLComponents(string: UIS_URL + "/authserver/needCaptcha.html")!
        component.queryItems = [URLQueryItem(name: "username", value: username)]
        let request = prepareRequest(component.url!)
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let result = String(data: data, encoding: String.Encoding.ascii) else {
            throw NetworkError.invalidResponse
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines) != "false"
    }
}
