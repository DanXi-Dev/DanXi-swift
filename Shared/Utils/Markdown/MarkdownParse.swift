import Foundation

extension String {
    // convert from NSRange to Range
    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location,
                                     limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length,
                                   limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self)
            else { return nil }
        return from ..< to
    }
    
    /// Convert Treehole-formatted content to basic markdown, stripping images and latex
    func stripToBasicMarkdown() -> String {
        let text = NSMutableString(string: self)
        
        _ = try? NSRegularExpression(pattern: #"\${1,2}.*?\${1,2}"#, options: .dotMatchesLineSeparators).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: NSLocalizedString("formula_tag", comment: "Formula Tag"))
        _ = try? NSRegularExpression(pattern: #"!\[.*?\]\(.*?\)"#).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: NSLocalizedString("image_tag", comment: "Image Tag"))
        _ = try? NSRegularExpression(pattern: #"#{1,2}[0-9]+\s*"#).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: "")
        
        return String(text)
    }
    
    func attributed() -> AttributedString {
        if let attributedString = try? AttributedString(markdown: self) {
            return attributedString
        }
        
        return AttributedString(self)
    }
    
    func inlineAttributed() -> AttributedString {
        return self.stripToBasicMarkdown().attributed()
    }
}

enum MarkdownElements: Identifiable {
    case text(content: String)
    case reference(floorId: Int) // empty reference
    case localReference(floor: THFloor) // reference within same hole
    case remoteReference(mention: THMention) // reference in different hole, with mention
    
    var id: UUID {
        UUID()
    }
}

@MainActor func parseMarkdownReferences(_ content: String,
                             mentions: [THMention] = [],
                             holeModel: HoleDetailViewModel? = nil) -> [MarkdownElements] {
    var partialContent = content
    var parsedResult: [MarkdownElements] = []
    let referencePattern = try! NSRegularExpression(pattern: #"##[0-9]+"#)
    
    while let searchResult = partialContent.range(from: referencePattern.rangeOfFirstMatch(in: partialContent, options: [], range: NSRange(location: 0, length: partialContent.utf16.count))) {
        
        // first part of text
        let previous = String(partialContent[partialContent.startIndex..<searchResult.lowerBound])
        if !previous.isEmpty {
            parsedResult.append(.text(content: previous))
        }
        
        // reference
        let floorId = Int(String(partialContent[searchResult]).dropFirst(2)) ?? 0
        var referenceElement = MarkdownElements.reference(floorId: floorId)
        
        
        if let floor = holeModel?.fetchFloorFromID(floorId) { // reference: check local
            referenceElement = .localReference(floor: floor)
        } else { // reference: check remote
            for mention in mentions {
                if mention.floorId == floorId {
                    referenceElement = .remoteReference(mention: mention)
                }
            }
        }
        
        parsedResult.append(referenceElement)
        
        
        // cut partial content
        partialContent = String(partialContent[searchResult.upperBound..<partialContent.endIndex])
    }
    
    if !partialContent.isEmpty { // last portion of text (if exist)
        parsedResult.append(.text(content: partialContent))
    }
    
    return parsedResult
}
