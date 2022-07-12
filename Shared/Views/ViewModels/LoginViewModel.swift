//
//  LoginViewModel.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2022/3/9.
//

import Foundation
import Alamofire

@MainActor
class LoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    
    @Published var isLoading: Bool = false
    @Published var hasError: Error? = nil
    
    func login() async -> JWToken? {
        isLoading = true
        hasError = nil
        defer { isLoading = false }
        
        do {
            let response = await AF.request(FDUHOLE_AUTH_URL + "/login", method: .post, parameters: ["email":username,"password":password], encoder: JSONParameterEncoder.default).serializingString().response
            guard let data = response.data else { throw TreeHoleError.invalidResponse }
            if (response.response?.statusCode ?? 999 >= 400) {
                let decodedResponse = try JSONDecoder().decode(ServerResponse.self, from: data)
                throw TreeHoleError.serverReturnedError(message: decodedResponse.message!)
            }
            let decodedJWT = try JSONDecoder().decode(JWToken.self, from: data)
            return decodedJWT
        } catch {
            hasError = error
            return nil
        }
    }
}
