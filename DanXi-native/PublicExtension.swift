//
//  PublicExtension.swift
//  DanXi-native
//
//  Created by Kavin Zhao on 2021/6/29.
//

import Foundation

extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        
        var string: NSAttributedString?
        string = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        return string
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}
