import SwiftUI
import DanXiKit
import MarkdownUI

struct FloorPresentation: Identifiable {
    init(floor: Floor, storey: Int, floors: [Floor] = []) {
        self.floor = floor
        self.storey = storey
        self.heightWrapped = effectiveLineCount(for: floor.content) > 250
        var cutContent = floor.content
        if self.heightWrapped {
            // cut the content to 500 characters
            cutContent = String(floor.content.prefix(500))
        } else {
            cutContent = floor.content
        }
        // self.sections = parseFloorContent(content: floor.content, mentions: floor.mentions, floors: floors)
        self.sections = parseFloorContent(content: temporaryFixForContentOverflow(cutContent), mentions: floor.mentions, floors: floors)
        self.replyTo = parseFirstMention(content: floor.content)
        self.imageURLs = parseFloorImageURLs(content: floor.content)
    }
    
    let id = UUID()
    let sections: [FloorSection]
    let imageURLs: [URL]
    let replyTo: Int?
    
    let floor: Floor
    let storey: Int
    
    // Whether the height of the content is wrapped
    let heightWrapped: Bool
}

enum FloorSection {
    case localMention(Floor)
    case remoteMention(Mention)
    case text(MarkdownContent)
}

func convertInlineImages(content: String) -> String {
    var modifiedContent = content
    let pattern = /!\[[^\]]*\]\((?<filename>https?:\/\/.*?)(?=\"|\))(?<optionalpart>\".*\")?\)/
    modifiedContent.replace(pattern) { match in
        "\n\n\(content[match.range])\n\n"
    }
    return modifiedContent
}

/// This is a temporary fix for issue #201 by removing deep quotes
func temporaryFixForContentOverflow(_ content: String) -> String {
    let pattern = "^(>){4,}"
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
        return content
    }
    let lines = content.components(separatedBy: .newlines)
    let processedLines = lines.map { line -> String in
        return regex.stringByReplacingMatches(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count), withTemplate: ">>>")
    }
    return processedLines.joined(separator: "\n")
}

func effectiveLineCount(for text: String, charsPerLine: Int = 30) -> Int {
    let lines = text.components(separatedBy: "\n")
    var effectiveLines = 0
    for line in lines {
        let charCount = line.count

        let lineCountForThisLine = max(Int(ceil(Double(charCount) / Double(charsPerLine))), 1)
        effectiveLines += lineCountForThisLine
    }
    return effectiveLines
}

func parseFloorContent(content: String, mentions: [Mention], floors: [Floor]) -> [FloorSection] {
    var partialContent = convertInlineImages(content: content)
    var sections: [FloorSection] = []
    var count = 0
    
    while let match = partialContent.firstMatch(of: /(?<prefix>#{1,2})(?<id>\d+)/) {
        // first part of text
        let previous = String(partialContent[partialContent.startIndex..<match.range.lowerBound])
        if !previous.isEmpty {
            count += 1
            let markdown = MarkdownContent(previous)
            sections.append(.text(markdown))
        }
        
        // match
        if match.prefix == "##" { // floor match
            let floorId = Int(match.id)
            if let floor = floors.filter({ $0.id == floorId }).first {
                count += 1
                sections.append(.localMention(floor))
            } else if let mention = mentions.filter({ $0.floorId == floorId }).first {
                count += 1
                sections.append(.remoteMention(mention))
            }
        } else if let holeId = Int(match.id) { // hole match
            if let mention = mentions.filter({ $0.holeId == holeId }).first {
                count += 1
                sections.append(.remoteMention(mention))
            }
        }
        
        // cut
        partialContent = String(partialContent[match.range.upperBound..<partialContent.endIndex])
    }
    
    sections.append(.text(MarkdownContent(partialContent)))
    return sections
}

func parseFloorImageURLs(content: String) -> [URL] {
    guard let attributed = try? AttributedString(markdown: content) else {
        return []
    }
    var imageURLs: [URL] = []
    for run in attributed.runs {
        if let imageURL = run.imageURL,
           Sticker(rawValue: imageURL.absoluteString) == nil {
            imageURLs.append(imageURL)
        }
    }
    return imageURLs
}

func parseFirstMention(content: String) -> Int? {
    let pattern = #/
        \#\#
        (?<id> \d+)
    /#
    if let result = content.firstMatch(of: pattern) {
        return Int(result.id)
    }
    return nil
}

extension Floor {
    var collapse: Bool {
        deleted || !fold.isEmpty
    }
}
