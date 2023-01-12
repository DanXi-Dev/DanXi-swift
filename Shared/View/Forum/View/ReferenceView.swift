import SwiftUI

/// View that parse and render Markdown and mention syntax.
///
/// Reference are a special syntax used in treehole to link to another floor/hole.
/// Hole reference starts with one hashtag, with hole ID follows: \#123456.
/// Floor reference are similar, except it starts with two hashtag: \#\#123456.
struct ReferenceView: View {
    let elements: [ReferenceType]
    
    
    /// Creates a reference view.
    /// - Parameters:
    ///   - content: Raw string of the content.
    ///   - mentions: Search base of remote mention, correspond to `floor.mentions`.
    ///   - floors: Search base of local mention.
    init(_ content: String,
         mentions: [THMention] = [],
         floors: [THFloor] = []) {
        elements = ReferenceView.parseReferences(content,
                                   mentions: mentions,
                                   floors: floors)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(elements) { element in
                switch element {
                case .text(let content):
                    MarkdownView(content)
                    
                case .localReference(let floor):
                    THMentionWrapper(floor: floor)
                    
                case .remoteReference(let mention):
                    THMentionWrapper(mention: mention)
                        .foregroundColor(.red)
                    
                case .reference(let floorId):
                    THRemoteMentionView(floorId: floorId)
                }
            }
        }
    }
    
    /// Types of elements appearing in a text with reference syntax.
    enum ReferenceType: Identifiable {
        /// Text content of floor
        case text(content: String)
        /// Empty reference
        case reference(floorId: Int)
        /// Reference linked to floor that local to this hole
        case localReference(floor: THFloor)
        /// Reference linked to another hole
        case remoteReference(mention: THMention)
        
        var id: UUID {
            UUID()
        }
    }
    
    /// Parse a string to different kind of references.
    ///
    /// Reference are a special syntax used in treehole to link to another floor/hole.
    /// Hole reference starts with one hashtag, with hole ID follows: \#123456.
    /// Floor reference are similar, except it starts with two hashtag: \#\#123456.
    /// - Parameters:
    ///   - content: Raw string of the content.
    ///   - mentions: Search base of remote mention, correspond to `floor.mentions`.
    ///   - floors: Search base of local mention.
    /// - Returns: A list of `ReferenceType`, correspond to parsed result.
    static func parseReferences(_ content: String,
                         mentions: [THMention] = [],
                         floors: [THFloor] = []) -> [ReferenceType] {
        var partialContent = content
        var parsedResult: [ReferenceType] = []
        let referencePattern = try! NSRegularExpression(pattern: #"##[0-9]+|#[0-9]+"#)
        
        while let searchResult = partialContent.range(from: referencePattern.rangeOfFirstMatch(in: partialContent, options: [], range: NSRange(location: 0, length: partialContent.utf16.count))) {
            
            // first part of text
            let previous = String(partialContent[partialContent.startIndex..<searchResult.lowerBound])
            if !previous.isEmpty {
                parsedResult.append(.text(content: previous))
            }
            
            // reference
            if partialContent[searchResult].hasPrefix("##") { // reference floor
                let floorId = Int(String(partialContent[searchResult]).dropFirst(2)) ?? 0
                var referenceElement = ReferenceType.reference(floorId: floorId)
                
                let matchedFloors = floors.filter { $0.id == floorId }
                let matchedMentions = mentions.filter { $0.floorId == floorId }
                
                if let floor = matchedFloors.first {
                    referenceElement = .localReference(floor: floor)
                } else if let mention = matchedMentions.first {
                    referenceElement = .remoteReference(mention: mention)
                }
                
                parsedResult.append(referenceElement)
            } else { // reference hole
                let holeId = Int(String(partialContent[searchResult]).dropFirst(1)) ?? 0
                
                let matchedMentions = mentions.filter { $0.holeId == holeId }
                if let mention = matchedMentions.first {
                    parsedResult.append(.remoteReference(mention: mention))
                }
                // TODO: when no hole match, show view that allow user to load
            }
            
            // cut partial content
            partialContent = String(partialContent[searchResult.upperBound..<partialContent.endIndex])
        }
        
        if !partialContent.isEmpty { // last portion of text (if exist)
            parsedResult.append(.text(content: partialContent))
        }
        
        return parsedResult
    }
}

extension String {
    /// Convert from NSRange to Range, simplify Regex matching process.
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
