import SwiftUI
import DanXiKit
import MarkdownUI

struct FloorPresentation: Identifiable {
    init(floor: Floor, storey: Int, floors: [Floor] = []) {
        self.floor = floor
        self.storey = storey
        self.sections = parseFloorContent(content: floor.content, mentions: floor.mentions, floors: floors)
        self.replyTo = parseFirstMention(content: floor.content)
        self.imageURLs = parseFloorImageURLs(content: floor.content)
    }
    
    let id = UUID()
    let sections: [FloorSection]
    let imageURLs: [URL]
    let replyTo: Int?
    
    let floor: Floor
    let storey: Int
}

enum FloorSection {
    case localMention(Floor)
    case remoteMention(Mention)
    case text(MarkdownContent)
}

func parseFloorContent(content: String, mentions: [Mention], floors: [Floor]) -> [FloorSection] {
    var partialContent = content
    var sections: [FloorSection] = []
    var count = 0
    
    while let match = partialContent.firstMatch(of: /(?<prefix>#{1,2})(?<id>\d+)/) {
        // first part of text
        let previous = String(partialContent[partialContent.startIndex..<match.range.lowerBound])
        if !previous.isEmpty {
            count += 1
            let markdown = MarkdownContent(previous)
            sections.append(FloorSection.text(markdown))
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
        } else {
            let holeId = Int(match.id)
            if let mention = mentions.filter({ $0.holeId == holeId }).first {
                count += 1
                sections.append(.remoteMention(mention))
            }
        }
        
        // cut
        partialContent = String(partialContent[match.range.upperBound..<partialContent.endIndex])
    }
    
    return sections
}

func parseFloorImageURLs(content: String) -> [URL] {
    guard let attributed = try? AttributedString(markdown: content) else {
        return []
    }
    var imageURLs: [URL] = []
    for run in attributed.runs {
        if let imageURL = run.imageURL {
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
