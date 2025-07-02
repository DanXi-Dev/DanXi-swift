import Foundation
import Utils
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
        
        return addedDate > Date.now
    }
    
    /// Authenticate a request and return the data required.
    /// - Parameters:
    ///   - url: The `URL`
    ///   - manualLoginURL: Some service require specific URL to login, set this optional parameter to provide one.
    /// - Returns: The business data.
    ///
    /// This function requests data from server, and perform authentication to services when necessary.
    /// Use this function to prevent duplicated UIS requests and concurrency issues.
    public func authenticate(_ url: URL, manualLoginURL: URL? = nil, method: AuthenticationMethod = .classic) async throws -> Data {
        let request = constructRequest(url)
        return try await authenticate(request, manualLoginURL: manualLoginURL, method: method)
    }
    
    public func neoAuthentication(_ request: URLRequest, manualLoginURL: URL? = nil) async throws -> (Data, URLResponse) {
        guard let host = request.url?.host(), let requestURL = request.url else { throw LocatableError() }
        
        // login once, mutex
        
        if !self.isLoggedIn(host: host) {
            let tryLoginTask = authenticationQueue.addBarrierOperation { () -> (Data, URLResponse)? in
                if self.isLoggedIn(host: host) { // more check inside barrier to prevent duplicated requests
                    return nil
                }
                
                let loginURL = manualLoginURL ?? requestURL
                let (data, response) = try await NeoAuthenticationAPI.authenticate(loginURL)
                self.hostLastLoggedInDate[host] = Date()
                
                if manualLoginURL == nil {
                    return (data, response)
                }
                
                return try await URLSession.campusSession.data(for: request)
            }
            
            if let result = try await tryLoginTask.value {
                return result
            }
        }
        
        // already logged-in, direct request, parallel
        
        let directRequestTask = authenticationQueue.addOperation {
            let (data, response) = try await URLSession.campusSession.data(for: request)
            if response.url?.host() != "id.fudan.edu.cn" {
                return (data, response)
            }
            
            // retry once
            let loginURL = manualLoginURL ?? requestURL
            let (authData, authResponse) = try await NeoAuthenticationAPI.authenticate(loginURL)
            self.hostLastLoggedInDate[host] = Date()
            
            if manualLoginURL == nil {
                return (authData, authResponse)
            }
            
            return try await URLSession.campusSession.data(for: request)
        }
        return try await directRequestTask.value
    }
    
    public func classicAuthentication(_ request: URLRequest, manualLoginURL: URL? = nil) async throws -> (Data, URLResponse) {
        guard let host = request.url?.host(), let method = request.httpMethod else { throw LocatableError() }
        
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
                    guard let baseURL = components.url else { throw LocatableError() }
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
    func authenticate(_ request: URLRequest, manualLoginURL: URL? = nil, method: AuthenticationMethod = .classic) async throws -> Data {
        let (data, _) = switch method {
        case .classic:
            try await classicAuthentication(request, manualLoginURL: manualLoginURL)
        case .neo:
            try await neoAuthentication(request, manualLoginURL: manualLoginURL)
        }
        return data
    }
}

public enum AuthenticationMethod {
    case classic
    case neo
}
