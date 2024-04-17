import Foundation
import SwiftyJSON

public enum GeneralAPI {
    
    // MARK: - Token
    
    public static func login(email: String, password: String) async throws -> Token {
        let payload = ["email": email, "password": password]
        return try await requestWithResponse("/login", base: authURL, protected: false, payload: payload)
    }
    
    public static func logout() async throws {
        try await requestWithoutResponse("/logout", base: authURL)
    }
    
    public static func refreshToken() async throws -> Token {
        guard let token = CredentialStore.shared.token else {
            throw URLError(.userAuthenticationRequired)
        }
        
        let refreshURL = authURL.appending(path: "/refresh")
        var refreshRequest = URLRequest(url: refreshURL)
        refreshRequest.httpMethod = "POST"
        refreshRequest.setValue(token.refresh, forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: refreshRequest)
        return try JSONDecoder().decode(Token.self, from: data)
    }
    
    // MARK: - Account
    
    public static func register(email: String, password: String, verification: String) async throws -> Token {
        let payload = ["email": email, "password": password, "verification": verification]
        return try await requestWithResponse("/register", base: authURL, protected: false, payload: payload)
    }
    
    public static func resetPassword(email: String, password: String, verification: String) async throws -> Token {
        let payload = ["email": email, "password": password, "verification": verification]
        return try await requestWithResponse("/register", base: authURL, protected: false, payload: payload, method: "PUT")
    }
    
    public static func sendVerificationEmail(email: String) async throws {
        try await requestWithoutResponse("/verify/email", base: authURL, protected: false, payload: ["email": email])
    }
    
    // MARK: Question
    
    public static func getQuestions() async throws -> Questions {
        return try await requestWithResponse("/register/questions", base: authURL)
    }
    
    public static func submitQuestions(answers: [Int: [String]], version: Int) async throws -> QuestionResponse {
        let answersMap: [[String: Any]] = answers.map { id, answer in
            ["id": id, "answer": answer]
        }
        let payload: [String: Any] = ["version": version, "answers": answersMap]
        let data = try await requestWithData("/register/questions/_answer", base: authURL, payload: payload)
        let json = try JSON(data: data)
        guard let correct = json["correct"].bool else {
            throw URLError(.badServerResponse)
        }
        if correct {
            guard let access = json["access"].string,
                  let refresh = json["refresh"].string else {
                throw URLError(.badServerResponse)
            }
            let token = Token(access: access, refresh: refresh)
            return .success(token)
        } else {
            guard let wrongQuestionsData = try? json["wrong_question_ids"].rawData(),
                  let wrongQustions = try? JSONDecoder().decode([Int].self, from: wrongQuestionsData) else {
                throw URLError(.badServerResponse)
            }
            return .fail(wrongQustions)
        }
    }
}
