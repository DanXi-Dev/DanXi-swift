//
//  THPostView.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/29.
//

import Foundation
import SwiftUI

struct THPostView: View {
    var discussion: THDiscussion
    
    func decodeHTML(string: String) -> String? {
        
        var decodedString: String?

        if let encodedData = string.data(using: .utf8) {
            let attributedOptions: [NSAttributedString.DocumentReadingOptionKey : Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]

            do {
                decodedString = try NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil).string
            } catch {
                print("\(error.localizedDescription)")
            }
        }

        return decodedString
    }
    
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
            Text(try! decodeHTML(string: discussion.posts[0].content)!)
            Spacer()
            HStack {
                Label("#\(discussion.id)", systemImage: "")
                Spacer()
                Label(discussion.date_created, systemImage: "")
                Spacer()
                Label("\(discussion.count)", systemImage: "ellipsis.bubble")
                    .padding(.trailing, 20)
            }
            .font(.caption)
        }
        .padding()
    }
}

struct THPostView_Previews: PreviewProvider {
    static var previews: some View {
        THPostView(discussion: THDiscussion(id: 123, count: 21, posts: [THReply(id: 456, discussion: 123, content: "HelloWorld", username: "Demo", date_created: "2021-10-01", reply_to: nil, is_me: false)], last_post: nil, is_folded: false, date_created: "xxx", date_updated: "xxx", tag: [THTag(name: "test", color: "red", count: 5)]))
    }
}
