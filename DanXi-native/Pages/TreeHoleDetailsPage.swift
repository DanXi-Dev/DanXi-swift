//
//  TreeHoleDetailsPage.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/7/1.
//

import SwiftUI

struct TreeHoleDetailsPage: View {
    @State private var replyList: [THReply]
    @State private var currentPage: Int = 1
    @State private var isLoading = false
    @State private var endReached = false
    @State private var errorReason: String? = nil
    
    init(replies: [THReply]) {
        replyList = replies
    }
    
    func loadMoreReplies() {
        currentPage += 1
        async {
            if (!isLoading) {
                isLoading = true
                do {
                    errorReason = nil
                    let newReplies: [THReply] = try await loadReplies(page: currentPage, discussionId: replyList.first!.discussion)
                    if(newReplies.isEmpty) {
                        endReached = true
                    }
                    else {
                        replyList.append(contentsOf: newReplies)
                    }
                    isLoading = false;
                }
                catch {
                    errorReason = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    var body: some View {
        List {
            ForEach(replyList) { reply in
                THPostDetailView(reply: reply)
            }
            if (!endReached && errorReason == nil) {
                ProgressView()
                    .onAppear(perform: loadMoreReplies)
            }
            else if (errorReason != nil) {
                ErrorView(errorInfo: errorReason ?? "Unknown Error")
                    .onTapGesture {
                        loadMoreReplies()
                    }
            }
            else {
                Text("end_reached")
            }
        }
        .navigationTitle("#\(replyList.first!.discussion)")
    }
}

struct TreeHoleDetailsPage_Previews: PreviewProvider {
    static var previews: some View {
        TreeHoleDetailsPage(replies: [THReply(id: 456, discussion: 123, content: "HelloWorld", username: "Demo", date_created: "xxx", reply_to: nil, is_me: false), THReply(id: 456, discussion: 123, content: "HelloWorld", username: "Demo", date_created: "xxx", reply_to: nil, is_me: false)])
    }
}
