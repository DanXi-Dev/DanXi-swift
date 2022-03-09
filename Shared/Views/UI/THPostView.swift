//
//  THPostView.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/29.
//

import Foundation
import SwiftUI
import MarkdownUI

func nsRange(self: String) -> NSRange {
    return NSRange(self.startIndex..., in: self)
}

func preprocessTextForHtmlAndImage(text: String) -> String {
    var processedText: String
    
    let imageHtmlRegex = try! NSRegularExpression(pattern: #"<img src=.*?>.*?</img>"#)
    processedText = imageHtmlRegex.stringByReplacingMatches(in: text, range: nsRange(self: text), withTemplate: NSLocalizedString("image_tag", comment: ""))
    
    let imageHtmlLooseRegex = try! NSRegularExpression(pattern: #"<img src=.*?>"#)
    processedText = imageHtmlLooseRegex.stringByReplacingMatches(in: processedText, range: nsRange(self: processedText), withTemplate: NSLocalizedString("image_tag", comment: ""))
    
    let imageMarkDownRegex = try! NSRegularExpression(pattern: #"!\[\]\(.*?\)"#)
    processedText = imageMarkDownRegex.stringByReplacingMatches(in: processedText, range: nsRange(self: processedText), withTemplate: NSLocalizedString("image_tag", comment: ""))
    
    let htmlTagRegex = try! NSRegularExpression(pattern: #"<.*?>"#)
    processedText = htmlTagRegex.stringByReplacingMatches(in: processedText, range: nsRange(self: processedText), withTemplate: "")
    
    let whiteSpaceRegex = try! NSRegularExpression(pattern: #"\s"#)
    processedText = whiteSpaceRegex.stringByReplacingMatches(in: processedText, range: nsRange(self: processedText), withTemplate: "")
    
    return processedText
}

struct THPostView: View {
    let hole: OTHole
    
    let KEY_NO_TAG = "默认"
    
    var body: some View {
        VStack(alignment: .leading) {
            // Discussion Tag
            if (hole.tags != nil && !hole.tags!.isEmpty && !hole.tags!.contains(where: {tag in if(tag.name == KEY_NO_TAG) {
                return true;
            }
            return false;
            })) {
                HStack {
                    ForEach(hole.tags!, id: \.self) { tag in
                        Text(tag.name)
                            .padding(EdgeInsets(top: 2,leading: 6,bottom: 2,trailing: 6))
                            .background(RoundedRectangle(cornerRadius: 24, style: .circular).stroke(Color.accentColor))
                            .foregroundColor(.accentColor)
                            .font(.system(size: 14))
                            .lineLimit(1)
                    }
                }
                .padding(.top)
            }
            else {
                Spacer()
            }
            
            // Begin Content
            if (!hole.floors.prefetch[0].fold!.isEmpty) {
                Label("discussionFolded", systemImage: "eye.slash")
                    .scaleEffect(0.8, anchor: .leading)
            }
            else {
                Markdown(hole.floors.prefetch[0].content)
                    .lineLimit(6)
            }
            Spacer()
            
            // Comment Count
            HStack(alignment: .bottom) {
                Label(String(hole.reply!), systemImage: "ellipsis.bubble")
                    .font(.footnote)
                    .imageScale(.small)
                /*Label(humanReadableDateString(dateString: discussion.date_created) , systemImage: "clock")
                 .lineLimit(1)
                 .font(.footnote)
                 .imageScale(.small)*/
            }
            .padding(.bottom)
        }
    }
}

struct THPostView_Previews: PreviewProvider {
    static var previews: some View {
        Text("too lazy to write preview")
    }
}