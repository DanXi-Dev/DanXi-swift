//
//  NetworkCache.swift
//  DanXi-native
//
//  Created by Singularity on 2022/8/11.
//

import Foundation

// This repository contains cache for commonly used data that doesn't or rarely change
// We use "get" to denote methods that involve cache, and "load" to denote methods that loads data from server
extension NetworkRequests {
    mutating func getTags(forceRefresh: Bool = false) async throws -> [THTag] {
        if (forceRefresh || tags.isEmpty) {
            let newTags = try await loadTags()
            tags = newTags
        }
        return tags
    }
}
