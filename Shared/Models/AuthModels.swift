//
//  AuthModels.swift
//  DanXi-native
//
//  Created by Singularity on 2022/6/23.
//

import Foundation

struct JWToken: Hashable, Codable {
    var access, refresh: String
}

struct User: Hashable, Codable {
    let token: JWToken?
}

enum UserState {
    case none
    case authorized(User)
}
