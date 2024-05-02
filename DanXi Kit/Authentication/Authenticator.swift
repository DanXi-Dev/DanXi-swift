import Foundation

actor Authenticator {
    static let shared = Authenticator()
    
    var refreshTask: Task<Void, any Error>? = nil
    
    func authenticate(request: URLRequest) async throws -> (Data, URLResponse) {
        // prepare request
        var authenticatedRequest = request
        guard let token = CredentialStore.shared.token else {
            throw URLError(.userAuthenticationRequired)
        }
        authenticatedRequest.setValue("Bearer \(token.access)", forHTTPHeaderField: "Authorization")
        
        // send request to server
        let (data, response) = try await URLSession.shared.data(for: authenticatedRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // request success, return response
        if httpResponse.statusCode != 401 {
            return (data, response)
        }
        
        // refresh token and retry
        if let refreshTask {
            try await refreshTask.value // a refreshing task is in place, wait for it to complete
        } else if token.access == CredentialStore.shared.token?.access {
            // no refreshing task is in place, create a new one
            let refreshTask = Task {
                if let token = try? await GeneralAPI.refreshToken() {
                    CredentialStore.shared.token = token
                } else {
                    throw URLError(.userAuthenticationRequired)
                }
            }
            self.refreshTask = refreshTask
            try await refreshTask.value
            self.refreshTask = nil
        }
        
        // reset token and retry
        if let token = CredentialStore.shared.token {
            authenticatedRequest.setValue("Bearer \(token.access)", forHTTPHeaderField: "Authorization")
        }
        return try await URLSession.shared.data(for: authenticatedRequest)
    }
}
