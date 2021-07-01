//
//  TreeHoleDetailsPage.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/7/1.
//

import SwiftUI

struct TreeHoleDetailsPage: View {
    var replies: [THReply]
    
    var body: some View {
        List(replies) { reply in
            THPostDetailView(reply: reply)
            Spacer()
        }
        .navigationTitle("title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TreeHoleDetailsPage_Previews: PreviewProvider {
    static var previews: some View {
        TreeHoleDetailsPage(replies: [THReply(id: 456, discussion: 123, content: "HelloWorld", username: "Demo", date_created: "xxx", reply_to: nil, is_me: false), THReply(id: 456, discussion: 123, content: "HelloWorld", username: "Demo", date_created: "xxx", reply_to: nil, is_me: false)])
    }
}
