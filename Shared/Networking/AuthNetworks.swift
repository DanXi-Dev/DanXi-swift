import Foundation

extension DXNetworks {
    
    // MARK: Account
    
    /// Request email verification code.
    /// - Parameter email: Email, must end with fudan domain name suffix.
    func verifyEmail(email: String) async throws {
        var components = URLComponents(string: FDUHOLE_AUTH_URL + "/verify/email")!
        components.queryItems = [URLQueryItem(name: "email", value: email)]
        _ = try await networkRequest(url: components.url!, authorize: false)
    }
    
    /// Register or change password, will reset authorization token.
    /// - Parameters:
    ///   - email: User account.
    ///   - password: New password.
    ///   - verification: Email verification code requested earlier.
    ///   - create: Create account or change password.
    func register(email: String,
                  password: String,
                  verification: String,
                  create: Bool) async throws {
        struct ChangePasswordConfig: Codable {
            let password: String
            let email: String
            let verification: String
        }
        
        let payload = ChangePasswordConfig(password: password,
                                           email: email,
                                           verification: verification)
        let token: Token = try await requestObj(url: URL(string: FDUHOLE_AUTH_URL + "/register")!, payload: payload, method: create ? "POST" : "PUT", authorize: false)
        storeToken(token)
    }
    
    // MARK: User
    
    /// Get current user info.
    func loadUserInfo() async throws -> DXUser {
        // FIXME: deprecated API, new: /users/me
        return try await requestObj(url: URL(string: FDUHOLE_BASE_URL + "/users")!)
    }
    
    // MARK: Authentication
    
    /// Login and store user token.
    /// - Parameters:
    ///   - username: username.
    ///   - password: password.
    func login(username: String, password: String) async throws {
        struct LoginBody: Codable {
            let email: String
            let password: String
        }
        
        let responseToken: Token =
        try await requestObj(url: URL(string: FDUHOLE_AUTH_URL + "/login")!,
                             payload: LoginBody(email: username, password: password),
                             authorize: false)
        storeToken(responseToken)
    }
    
    /// Logout and invalidate token.
    func logout() {
        // TODO: call API
        storeToken(nil)
    }
    
    /// Request a new token when current token is expired.
    func refreshToken() async throws {
        guard let token = self.token else {
            throw NetworkError.forbidden
        }
        
        do {
            var request = URLRequest(url: URL(string: FDUHOLE_AUTH_URL + "/refresh")!)
            request.setValue("Bearer \(token.refresh)", forHTTPHeaderField: "Authorization")
            request.httpMethod = "POST"
            let (data, _) = try await URLSession.shared.data(for: request)
            let responseToken = try JSONDecoder().decode(Token.self, from: data)
            defaults?.setValue(data, forKey: "user-credential")
            self.token = responseToken
        } catch {
            throw NetworkError.unauthorized
        }
    }
}
