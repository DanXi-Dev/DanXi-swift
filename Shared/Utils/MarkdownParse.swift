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
}

enum MarkdownElements: Identifiable {
    case text(content: String)
    case reference(floorId: Int, mention: THMention?)
    
    var id: UUID {
        UUID()
    }
}

func parseMarkdownReferences(content: String, mentions: [THMention] = []) -> [MarkdownElements] {
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

        var correspondMention: THMention?
        for mention in mentions {
            if mention.floorId == floorId {
                correspondMention = mention
            }
        }
        
        parsedResult.append(.reference(floorId: floorId, mention: correspondMention))
        
        // cut partial content
        partialContent = String(partialContent[searchResult.upperBound..<partialContent.endIndex])
    }
    
    if !partialContent.isEmpty { // last portion of text (if exist)
        parsedResult.append(.text(content: partialContent))
    }
    
    return parsedResult
}
