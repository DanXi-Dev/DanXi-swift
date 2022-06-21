//
//  AccountViewModel.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2022/3/8.
//

import Foundation
import Combine

struct AppManager {
    static let uisAuthenticated = PassthroughSubject<Bool, Never>()
    static let fduholeAuthenticated = PassthroughSubject<Bool, Never>()
    
    static func isUisAuthenticated() -> Bool {
        return false
    }
    static func isFduholeAuthenticated() -> Bool {
        return DefaultsManager.shared.fduholeToken != nil
    }
}
