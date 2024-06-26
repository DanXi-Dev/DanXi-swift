import Foundation
import Queue


/// A central object that handle all UIS login requests.
///
/// Use this object to authenticate for all services to prevent duplicated authentication requests and concurrency issues.
public actor Authenticator {
    public static let shared = Authenticator()
    
    let authenticationQueue = AsyncQueue(attributes: [.concurrent])
    var hostLastLoggedInDate: [String: Date] = [:]
    
    /// Determine whether the given host has credential or whether the credential has expired.
    ///
    /// If it has been 2 hours since last login, the credential is regarded expired.
    private func isLoggedIn(host: String) -> Bool {
        guard let loginDate = hostLastLoggedInDate[host] else {
            return false
        }
        
        var dateComponents = DateComponents()
        dateComponents.hour = 2
        
        let calendar = Calendar.current
        guard let addedDate = calendar.date(byAdding: dateComponents, to: loginDate) else { return false }
        
        return addedDate < Date.now
    }
    
    /// Authenticate a request and return the data required.
    /// - Parameters:
    ///   - url: The `URL`
    ///   - manualLoginURL: Some service require specific URL to login, set this optional parameter to provide one.
    /// - Returns: The business data.
    ///
    /// This function requests data from server, and perform authentication to services when necessary.
    /// Use this function to prevent duplicated UIS requests and concurrency issues.
    func authenticate(_ url: URL, manualLoginURL: URL? = nil) async throws -> Data {
        let request = constructRequest(url)
        return try await authenticate(request, manualLoginURL: manualLoginURL)
    }
    
    
    public func authenticateWithResponse(_ request: URLRequest, manualLoginURL: URL? = nil) async throws -> (Data, URLResponse) {
        guard let host = request.url?.host(), let method = request.httpMethod else { throw URLError(.badURL) }
        
        // GET request is redirected to UIS. If the request is not GET, we should manually login once.
        if !isLoggedIn(host: host) && (method != "GET" || manualLoginURL != nil) {
            let preloginTask = authenticationQueue.addBarrierOperation {
                if self.isLoggedIn(host: host) { return } // prevent duplicated request
                
                if let manualLoginURL = manualLoginURL {
                    _ = try await AuthenticationAPI.authenticateForData(manualLoginURL)
                } else {
                    var components = URLComponents()
                    components.scheme = request.url?.scheme
                    components.host = request.url?.host()
                    guard let baseURL = components.url else { throw URLError(.badURL) }
                    _ = try await AuthenticationAPI.authenticateForData(baseURL)
                }
                self.hostLastLoggedInDate[host] = Date()
            }
            
            try await preloginTask.value
        }
        
        // try login once, mutex
        
        if !self.isLoggedIn(host: host) {
            let tryLoginTask = authenticationQueue.addBarrierOperation { () -> (Data, URLResponse)? in
                if self.isLoggedIn(host: host) { // more check inside barrier to prevent duplicated requests
                    return nil
                }
                let (data, response) = try await URLSession.campusSession.data(for: request)
                if response.url?.host() != "uis.fudan.edu.cn" {
                    return (data, response)
                }
                
                guard let username = CredentialStore.shared.username,
                      let password = CredentialStore.shared.password else {
                    throw CampusError.credentialNotFound
                }
                
                let request = try AuthenticationAPI.constructAuthenticationRequest(response.url!, form: data, username: username, password: password)
                let (reloadedData, reloadedResponse) = try await URLSession.campusSession.data(for: request)
                guard reloadedResponse.url?.host() != "uis.fudan.edu.cn" else {
                    throw CampusError.loginFailed
                }
                self.hostLastLoggedInDate[host] = Date() // refresh isLogged status
                return (reloadedData, reloadedResponse)
            }
            
            if let result = try await tryLoginTask.value {
                return result
            }
        }
        
        // already logged-in, direct request, parallel
        
        let directRequestTask = authenticationQueue.addOperation {
            let (data, response) = try await URLSession.campusSession.data(for: request)
            if response.url?.host() != "uis.fudan.edu.cn" {
                return (data, response)
            }
            
            // retry once
            guard let username = CredentialStore.shared.username,
                  let password = CredentialStore.shared.password else {
                throw CampusError.credentialNotFound
            }
            
            let request = try AuthenticationAPI.constructAuthenticationRequest(response.url!, form: data, username: username, password: password)
            let (reloadedData, reloadedResponse) = try await URLSession.campusSession.data(for: request)
            guard reloadedResponse.url?.host() != "uis.fudan.edu.cn" else {
                throw CampusError.loginFailed
            }
            self.hostLastLoggedInDate[host] = Date() // refresh isLogged status
            return (reloadedData, reloadedResponse)
        }
        
        return try await directRequestTask.value
    }
    
    
    /// Authenticate a request and return the data required.
    /// - Parameters:
    ///   - request: The `URLRequest`
    ///   - manualLoginURL: Some service require specific URL to login, set this optional parameter to provide one.
    /// - Returns: The business data.
    ///
    /// This function requests data from server, and perform authentication to services when necessary.
    /// Use this function to prevent duplicated UIS requests and concurrency issues.
    func authenticate(_ request: URLRequest, manualLoginURL: URL? = nil) async throws -> Data {
        let (data, _) = try await authenticateWithResponse(request, manualLoginURL: manualLoginURL)
        return data
    }
}
