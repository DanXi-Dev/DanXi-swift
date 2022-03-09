//
//  LoginViewModel.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2022/3/9.
//

import Foundation

@MainActor
class LoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    
    @Published var isLoading: Bool = false
    @Published var hasError: Error? = nil
    
    func login() async {
        isLoading = true
        hasError = nil
        defer { isLoading = false }
        
        do {
            let token = try await TreeHoleRepository.shared.loginWithUsernamePassword(username: username, password: password)
            DefaultsManager.shared.fduholeToken = token
            AppManager.fduholeAuthenticated.send(true)
        } catch {
            hasError = error
        }
    }
}
