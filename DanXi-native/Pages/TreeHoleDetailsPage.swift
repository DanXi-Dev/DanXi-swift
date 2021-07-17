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
    @State private var discussionId: Int
    @State private var isLoading = false
    @State private var endReached = false
    @State private var errorReason: String? = nil
    
    init(replies: [THReply]) {
        replyList = replies
        discussionId = replies.first?.discussion ?? 0
    }
    
    func loadMoreReplies(clearAll: Bool = false) async {
        currentPage += 1
        if (!isLoading) {
            isLoading = true
            do {
                errorReason = nil
                let newReplies: [THReply] = try await loadReplies(page: currentPage, discussionId: discussionId)
                if(newReplies.isEmpty) {
                    endReached = true
                }
                else {
                    if (clearAll) {
                        replyList = newReplies
                    }
                    else {
                        replyList.append(contentsOf: newReplies)
                    }
                }
                isLoading = false;
            }
            catch {
                errorReason = error.localizedDescription
                isLoading = false
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
                    .onAppear {
                        async {
                            await loadMoreReplies()
                        }
                    }
            }
            else if (errorReason != nil) {
                ErrorView(errorInfo: errorReason ?? "Unknown Error")
                    .onTapGesture {
                        async {
                            await loadMoreReplies()
                        }
                    }
            }
            else {
                Text("end_reached")
            }
        }
        .navigationBarTitle("#\(discussionId)")
        .refreshable {
            currentPage = 0
            await loadMoreReplies(clearAll: true)
        }
    }
}

struct TreeHoleDetailsPage_Previews: PreviewProvider {
    static var previews: some View {
        TreeHoleDetailsPage(replies: [THReply(id: 456, discussion: 123, content: "HelloWorld", username: "Demo", date_created: "xxx", reply_to: nil, is_me: false), THReply(id: 456, discussion: 123, content: "HelloWorld", username: "Demo", date_created: "xxx", reply_to: nil, is_me: false)])
    }
}
