//
//  THPostView.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/29.
//

import SwiftUI

struct THPostView: View {
    var discussion: THDiscussion
    
    var body: some View {
        VStack(alignment: .leading) {
            if (discussion.tag != nil && !discussion.tag!.isEmpty) {
                HStack {
                    ForEach(discussion.tag!, id: \.self) { tag in
                        Text(tag.name)
                            .padding(EdgeInsets(top: 4,leading: 8,bottom: 4,trailing: 8))
                            .background(RoundedRectangle(cornerRadius: 24, style: .circular).stroke(Color.red))
                            .foregroundColor(Color.red)
                    }
                }
            }
            Text(discussion.first_post.content)
                .font(.headline)
            Spacer()
            HStack {
                Label("\(discussion.count)", systemImage: "person.3")
                Spacer()
                Label("\(discussion.id)", systemImage: "clock")
                    .padding(.trailing, 20)
            }
            .font(.caption)
        }
        .padding()
    }
}

struct THPostView_Previews: PreviewProvider {
    static var previews: some View {
        THPostView(discussion: THDiscussion(id: 123, count: 21, first_post: THReply(id: 456, discussion: 123, content: "HelloWorld", username: "Demo", date_created: "xxx", reply_to: nil, is_me: false), last_post: nil, is_folded: false, date_created: "xxx", date_updated: "xxx", tag: [THTag(name: "test", color: "red", count: 5)]))
    }
}
