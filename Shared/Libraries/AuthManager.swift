//
//  AccountViewModel.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2022/3/8.
//

import Foundation
import Combine

struct AuthManager {
    static let AuthUserChanged = PassthroughSubject<User, Never>()
}
