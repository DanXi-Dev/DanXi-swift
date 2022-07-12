//
//  AuthModels.swift
//  DanXi-native
//
//  Created by Singularity on 2022/6/23.
//

import Foundation

class AppModel: ObservableObject {
    @Published var account: OTUser?
    
    var hasAccount: Bool {
        return userCredential != nil
    }
    
    let defaults = UserDefaults(suiteName: "group.io.github.kavinzhao.fdutools")
    
    @Published var userCredential: JWToken? {
        didSet {
            do {
                let data = try JSONEncoder().encode(userCredential)
                let string = String(data: data, encoding: .utf8)
                defaults?.setValue(string, forKey: "UserCredential")
            } catch {
                print("Failed to save JWT")
            }
        }
    }
    
    func getUserCredentials() -> JWToken? {
        let json = defaults?.string(forKey: "UserCredential")
        guard let data = json?.data(using: .utf8) else { return nil }
        do {
            let jwt = try JSONDecoder().decode(JWToken.self, from: data)
            print(jwt)
            return jwt
        }
        catch {
            return nil
        }
    }
    
    init() {
        userCredential = getUserCredentials()
    }
    
    deinit {
        
    }
}

struct JWToken: Hashable, Codable {
    var access, refresh: String
}

struct ServerResponse: Hashable, Codable {
    var message, token: String?
}

public enum TreeHoleError: LocalizedError {
    case unauthorized
    case notInitialized
    case serverReturnedError(message: String)
    case invalidResponse
}

extension TreeHoleError {
    public var errorDescription: String? {
        switch self {
        case let .serverReturnedError(message):
            return message
        case .unauthorized:
            return "Unauthorized"
        case .notInitialized:
            return "Repository not initialized"
        case .invalidResponse:
            return "The server returned an invalid response"
        }
    }
}
