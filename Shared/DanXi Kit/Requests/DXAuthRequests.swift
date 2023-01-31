import Foundation

struct DXAuthRequests {
    
    // MARK: Account
    
    /// Request email verification code.
    /// - Parameter email: Email, must end with fudan domain name suffix.
    static func verifyEmail(email: String) async throws {
        var components = URLComponents(string: FDUHOLE_AUTH_URL + "/verify/email")!
        components.queryItems = [URLQueryItem(name: "email", value: email)]
        let request = prepareRequest(components.url!)
        _ = try await sendRequest(request)
    }
    
    /// Register or change password, will reset authorization token.
    /// - Parameters:
    ///   - email: User account.
    ///   - password: New password.
    ///   - verification: Email verification code requested earlier.
    ///   - create: Create account or change password.
    static func register(email: String,
                  password: String,
                  verification: String,
                         create: Bool) async throws -> Token {
        struct ChangePasswordConfig: Codable {
            let password: String
            let email: String
            let verification: String
        }
        
        do {
            let payload = ChangePasswordConfig(password: password,
                                               email: email,
                                               verification: verification)
            let method = create ? "POST" : "PUT"
            let request = try prepareJSONRequest(URL(string: FDUHOLE_AUTH_URL + "/register")!, payload: payload, method: method)
            let (data, _) = try await sendRequest(request)
            return try processJSONData(data)
        } catch HTTPError.badRequest(let message) {
            throw DanXiError.registerFailed(message: message)
        }
    }
    
    // MARK: User
    
    /// Get current user info.
    static func loadUserInfo() async throws -> DXUser {
        return try await DXResponse(URL(string: FDUHOLE_BASE_URL + "/users/me")!)
    }
    
    /// Modify user's nickname.
    /// - Parameters:
    ///   - userId: User ID.
    ///   - nickname: New nickname.
    /// - Returns: New user struct.
    static func modifyUser(userId: Int, nickname: String) async throws -> DXUser {
        struct NicknameConfig: Codable {
            let nickname: String
        }
        
        let payload = NicknameConfig(nickname: nickname)
        return try await DXResponse(URL(string: "/users/\(userId)")!, payload: payload, method: "PUT")
    }
    
    // MARK: Authentication
    
    /// Login and get user token.
    /// - Parameters:
    ///   - username: username.
    ///   - password: password.
    /// - Returns: User token.
    static func login(username: String, password: String) async throws -> Token {
        struct LoginBody: Codable {
            let email: String
            let password: String
        }
        
        do {
            let payload = LoginBody(email: username, password: password)
            let request = try prepareJSONRequest(URL(string: FDUHOLE_AUTH_URL + "/login")!, payload: payload)
            let (data, _) = try await sendRequest(request)
            return try processJSONData(data)
        } catch HTTPError.unauthorized {
            throw DanXiError.loginFailed
        }
    }
    
    /// Logout and invalidate token.
    static func logout() async throws {
        try await DXRequest(URL(string: FDUHOLE_AUTH_URL + "/logout")!)
    }
    
    /// Request a new token when current token is expired.
    /// - Returns: New token.
    static func refreshToken() async throws -> Token {
        guard let token = DXSecStore.shared.token else {
            throw DanXiError.tokenNotFound
        }
        
        do {
            var request = prepareRequest(URL(string: FDUHOLE_AUTH_URL + "/refresh")!, method: "POST")
            request.setValue("Bearer \(token.refresh)", forHTTPHeaderField: "Authorization")
            let (data, _) = try await sendRequest(request)
            return try processJSONData(data)
        } catch {
            throw DanXiError.tokenExpired
        }
    }
    
    // TODO: Permission
}