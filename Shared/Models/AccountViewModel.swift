//
//  AccountViewModel.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2022/3/8.
//

import Foundation

@MainActor
class AccountViewModel: ObservableObject {
    @Published var isFduholeAuthenticated = false
    
    func setFduholeAuthenticationStatus(value: Bool) {
        Task{
            await MainActor.run {
                self.isFduholeAuthenticated = value
            }
        }
    }
}
