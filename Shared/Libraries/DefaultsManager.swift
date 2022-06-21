//
//  DefaultsManager.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2022/3/9.
//

import Foundation

class DefaultsManager {
    static let shared = DefaultsManager()
    private init() {}
    
    let defaults = UserDefaults(suiteName: "group.io.github.kavinzhao.fdutools")!
    
    let KEY_FDUHOLE_TOKEN = "ft"
    
    var fduholeToken: String? {
        get {
            return self.defaults.string(forKey: KEY_FDUHOLE_TOKEN)
        }
        set {
            self.defaults.set(newValue, forKey: KEY_FDUHOLE_TOKEN)
        }
    }
}
