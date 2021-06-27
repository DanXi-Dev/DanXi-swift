//
//  Discussion.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/26.
//

import Foundation

struct THDiscussion: Hashable, Codable, Identifiable {
    var id, count: Int
    var first_post, last_post: THReply?
    var is_folded: Bool
    var date_created, date_updated: String
}

struct THReply: Hashable, Codable, Identifiable {
    var id, discussion: Int
    var content, username, date_created: String
    var reply_to: Int?
    var is_me: Bool?
}
