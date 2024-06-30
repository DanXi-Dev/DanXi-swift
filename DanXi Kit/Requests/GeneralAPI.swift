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
            throw TokenError.none
        }
        
        let refreshURL = authURL.appending(path: "/refresh")
        var refreshRequest = URLRequest(url: refreshURL)
        refreshRequest.httpMethod = "POST"
        refreshRequest.setValue("Bearer \(token.refresh)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await Proxy.shared.data(for: refreshRequest)
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
        try await requestWithoutResponse("/verify/email", base: authURL, protected: false, params: ["email": email], method: "GET")
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
    
    // MARK: Image
    
    public static func uploadImage(_ imageData: Data) async throws -> URL {
        func formParam(_ boundaryData: Data, key: String, value: String) -> Data {
            var data = Data()
            data.append(boundaryData)
            data.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: String.Encoding.utf8)!)
            data.append(value.data(using: String.Encoding.utf8)!)
            return data
        }
        
        // prepare URL requst and metadata
        let url = URL(string: "https://image.fduhole.com/json")!
        let boundary = UUID().uuidString
        let boundaryData = "\r\n--\(boundary)\r\n".data(using: String.Encoding.utf8)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // append text values
        var data = Data()
        data.append(formParam(boundaryData, key: "type", value: "file"))
        data.append(formParam(boundaryData, key: "action", value: "upload"))
        data.append(formParam(boundaryData, key: "auth_token", value: "123456789"))
        
        // append image data
        data.append(boundaryData)
        data.append("Content-Disposition: form-data; name=\"source\"; filename=\"image.png\"\r\n".data(using: String.Encoding.utf8)!)
        data.append("Content-Type: image/png\r\n\r\n".data(using: String.Encoding.utf8)!)
        data.append(imageData)
        data.append("\r\n--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
        
        // request and process response
        let (responseData, _) = try await URLSession.shared.upload(for: request, from: data)
        guard let responseObject = try? JSON(data: responseData),
              let urlString = responseObject["image", "url"].string,
              let url = URL(string: urlString) else {
            throw URLError(.badServerResponse)
        }
        return url
    }
}
