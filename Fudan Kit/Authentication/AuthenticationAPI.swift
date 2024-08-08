import Foundation

/// APIs that handle the authentication process with UIS system
///
/// Most campus APIs are protected by the UIS system, which handles the authentication process
/// of user. To access a specific site, one will be redirected to
/// `https://uis.fudan.edu.cn/authserver/login?service=[site url]`.
/// When the user is authenticated, he will be redirecred back to the original site with proper credential.
/// This process is known as SSO.
///
/// After a successful login, the UIS will store cookies on user's device, so the next time user need to
/// authenticate, it can redirect immediately without asking for the user's credential.
public enum AuthenticationAPI {

    /// The UIS service URL
    private static let authenticationURL = URL(string: "https://uis.fudan.edu.cn/authserver/login")!
    
    /// Check if the user's credential is correct.
    /// - Returns: `true` if user's credential is correct, `false` otherwise.
    public static func checkUserCredential(username: String, password: String) async throws -> Bool {        
        let request = constructRequest(authenticationURL)
        let (loginFormData, _) = try await URLSession.campusSession.data(for: request)
        let authRequest = try constructAuthenticationRequest(authenticationURL, form: loginFormData, username: username, password: password)
        let (_, response) = try await URLSession.campusSession.data(for: authRequest)
        
        return response.url?.absoluteString == "https://uis.fudan.edu.cn/authserver/index.do"
    }
    
    /// Check if the user's login is captcha protected.
    ///
    /// When user try to login, there might be a captcha check. The app cannot automatically handle this case, so it need
    /// to prompt user to manually login once to eliminate captcha. This function represents whether such a captcha check
    /// exists.
    ///
    /// - Important:
    /// To prevent the login process to stuck on this API, this function never throws error. When an error occurs, it simply return `false`.
    @available(*, deprecated, message: "This API is not accurate")
    static func checkCaptchaStatus(username: String) async -> Bool {
        do {
            guard let url = URL(string: "https://uis.fudan.edu.cn/authserver/needCaptcha.html?username=\(username)") else {
                return false
            }
            let request = constructRequest(url)
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let result = String(data: data, encoding: String.Encoding.ascii) else {
                return false
            }
            return result.trimmingCharacters(in: .whitespacesAndNewlines) != "false"
        } catch {
            return false
        }
    }
    
    /// Authenticate the request and return the data retrieved
    public static func authenticateForData(_ url: URL) async throws -> Data {
        guard let username = CredentialStore.shared.username,
              let password = CredentialStore.shared.password else {
            throw CampusError.credentialNotFound
        }
        
        // construct authentication URLRequest
        var components = URLComponents(string: authenticationURL.absoluteString)!
        components.queryItems = [URLQueryItem(name: "service", value: url.absoluteString)]
        let authRequest = constructRequest(components.url!)
        let (data, response) = try await URLSession.campusSession.data(for: authRequest)
        
        // if local cookie is not expired, the response will be returned directly
        // otherwise, this will redirect to UIS page
        guard response.url?.host == authenticationURL.host else {
            return data
        }
        
        let dataRequest = try constructAuthenticationRequest(components.url!, form: data, username: username, password: password)
        let (authData, authResponse) = try await URLSession.campusSession.data(for: dataRequest)
        guard authResponse.url?.host != authenticationURL.host else {
            throw CampusError.loginFailed
        }
        return authData
    }
    
    /// Authenticate the request and return the authenticated URL callback (with a `ticket` parameter for authentication)
    ///
    /// Use case: some system components, such as `SafariController`, only accept `URL` rather than `URLRequest`.
    /// To share credential with such components, an authenticated URL, i.e., a URL with `ticket` param must be passed to authenticate user.
    public static func authenticateForURL(_ url: URL) async throws -> URL {
        // use delegate to intercept redirecting URL
        final class RedirectDelegate: NSObject, URLSessionTaskDelegate {
            func urlSession(
                _ session: URLSession,
                task: URLSessionTask,
                willPerformHTTPRedirection response: HTTPURLResponse,
                newRequest request: URLRequest,
                completionHandler: @escaping @Sendable (URLRequest?) -> Void
            ) {
                completionHandler(nil)
            }
        }
        
        guard let username = CredentialStore.shared.username,
              let password = CredentialStore.shared.password else {
            throw CampusError.credentialNotFound
        }
        
        // create a temp session to prevent cookie store and force redirecting
        let session = URLSession(configuration: .ephemeral)
        
        var components = URLComponents(string: authenticationURL.absoluteString)!
        components.queryItems = [URLQueryItem(name: "service", value: url.absoluteString)]
        let request = constructRequest(components.url!)
        let (data, _) = try await session.data(for: request)
        
        let authRequest = try constructAuthenticationRequest(components.url!, form: data, username: username, password: password)
        let (_, newResponse) = try await session.data(for: authRequest, delegate: RedirectDelegate())
        guard let httpResponse = newResponse as? HTTPURLResponse,
              let header = httpResponse.value(forHTTPHeaderField: "Location"),
              let url = URL(string: header) else {
            throw URLError(.badServerResponse)
        }
        return url
    }
    
    /// Fill in the authentication form and construct a POST request
    static func constructAuthenticationRequest(_ url: URL, form: Data, username: String, password: String) throws -> URLRequest {
        var loginForm = ["username": username, "password": password]
        
        if existHTMLElement(form, selector: "#captchaResponse") {
            throw CampusError.needCaptcha
        }
        
        // search for `<input type="hidden">` and add value to the form
        let elements = try decodeHTMLElementList(form, selector: "input[type=\"hidden\"]")
        for element in elements {
            loginForm[try element.attr("name")] = try element.attr("value")
        }
        
        return constructFormRequest(url, form: loginForm)
    }
}
