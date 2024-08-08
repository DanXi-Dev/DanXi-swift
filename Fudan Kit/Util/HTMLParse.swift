import Foundation
import SwiftSoup

func existHTMLElement(_ data: Data, selector: String) -> Bool {
    guard let text = String(data: data, encoding: String.Encoding.utf8),
          let doc = try? SwiftSoup.parse(text),
          let list = try? doc.select(selector) else {
        return false
    }
    
    return !list.isEmpty
}

func decodeHTMLDocument(_ data: Data) throws -> Document {
    guard let text = String(data: data, encoding: String.Encoding.utf8) else {
        throw URLError(.cannotDecodeContentData)
    }
    
    return try SwiftSoup.parse(text)
}

func decodeHTMLElement(_ data: Data, selector: String) throws -> Element {
    guard let text = String(data: data, encoding: String.Encoding.utf8) else {
        throw URLError(.cannotDecodeContentData)
    }
    
    let doc = try SwiftSoup.parse(text)
    guard let element = try doc.select(selector).first() else {
        throw URLError(.badServerResponse)
    }
    
    return element
}

func decodeHTMLElementList(_ data: Data, selector: String) throws -> Elements {
    guard let text = String(data: data, encoding: String.Encoding.utf8) else {
        throw URLError(.cannotDecodeContentData)
    }
    
    let document = try SwiftSoup.parse(text)
    return try document.select(selector)
}
