import Foundation
import Queue

actor Authenticator {
    static let shared = Authenticator()
    
    let authenticationQueue = AsyncQueue(attributes: [.concurrent])
    var hostLastLoggedInDate: [String: Date] = [:]
    
    /// Determine whether the given host has credential or whether the credential has expired.
    ///
    /// If it has been 2 hours since last login, the credential is regared expired.
    func isLoggedIn(host: String) -> Bool {
        guard let loginDate = hostLastLoggedInDate[host] else {
            return false
        }
        
        let currentDate = Date()
        let calendar = Calendar.current
        let hours = calendar.dateComponents([.hour], from: loginDate, to: currentDate).hour ?? 0
        
        return hours < 2
    }
    
    func authenticate(_ url: URL, manualLoginURL: URL? = nil) async throws -> Data {
        let request = constructRequest(url)
        return try await authenticate(request, manualLoginURL: manualLoginURL)
    }
    
    func authenticate(_ request: URLRequest, manualLoginURL: URL? = nil) async throws -> Data {
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
        
        let tryLoginTask = authenticationQueue.addBarrierOperation { () -> Data? in
            if self.isLoggedIn(host: host) {
                return nil
            }
            let (data, response) = try await URLSession.campusSession.data(for: request)
            if response.url?.host() != "uis.fudan.edu.cn" {
                return data
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
            return reloadedData
        }
        
        if let data = try await tryLoginTask.value {
            return data
        }
        
        // already logged-in, direct request, parallel
        
        let directRequestTask = authenticationQueue.addOperation {
            let (data, response) = try await URLSession.campusSession.data(for: request)
            guard response.url?.host() != "uis.fudan.edu.cn" else {
                throw CampusError.loginFailed
            }
            return data
        }
        
        return try await directRequestTask.value
    }
}
