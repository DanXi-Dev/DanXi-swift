import Foundation
import DanXiKit

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
    case text(MarkdownDocument)
}

/// Normalizes downloaded floor content to Unix LF line endings before other preprocessing.
///
/// The forum API may return CRLF line endings. Treating CR and LF as separate delimiters inserts
/// blank lines when the content is rejoined, which breaks the consecutive rows required by
/// Markdown tables. Replacing CRLF first also prevents it from being converted into two LF characters.
func normalizeLineEndings(content: String) -> String {
    content
        .replacingOccurrences(of: "\r\n", with: "\n")
        .replacingOccurrences(of: "\r", with: "\n")
}

/// This is a temporary fix for issue #201 by removing deep quotes
func temporaryFixForContentOverflow(_ content: String) -> String {
    let protected = MarkdownSource(content)
    var result = content
    for match in content.matches(of: /(?m)^>{4,}/).reversed() {
        guard !protected.protects(match.range) else { continue }
        result.replaceSubrange(match.range, with: ">>>")
    }
    return result
}

func preprocessFloorContent(content: String) -> String {
    temporaryFixForContentOverflow(normalizeLineEndings(content: content))
}

func parseFloorContent(content: String, mentions: [Mention], floors: [Floor]) -> [FloorSection] {
    let source = preprocessFloorContent(content: content)
    let protected = MarkdownSource(source)
    var sections: [FloorSection] = []
    var start = source.startIndex
    for match in source.matches(of: /(?<prefix>#{1,2})(?<id>\d+)/) {
        guard !protected.protects(match.range) else { continue }
        let section: FloorSection?
        if match.prefix == "##", let id = Int(match.id) {
            if let floor = floors.first(where: { $0.id == id }) { section = .localMention(floor) }
            else if let mention = mentions.first(where: { $0.floorId == id }) { section = .remoteMention(mention) }
            else { section = nil }
        } else if let id = Int(match.id), let mention = mentions.first(where: { $0.holeId == id }) {
            section = .remoteMention(mention)
        } else { section = nil }
        // Unknown references are still source text; never eat #123 or a CSS color.
        guard let section else { continue }
        if start < match.range.lowerBound {
            sections.append(.text(MarkdownDocument(String(source[start..<match.range.lowerBound]))))
        }
        sections.append(section)
        start = match.range.upperBound
    }
    if start < source.endIndex { sections.append(.text(MarkdownDocument(String(source[start...])))) }
    return sections
}

func parseFloorImageURLs(content: String) -> [URL] {
    guard let attributed = try? AttributedString(markdown: content) else {
        return []
    }
    var imageURLs: [URL] = []
    for run in attributed.runs {
        if let imageURL = run.imageURL,
           imageURL.absoluteString.starts(with: "http") {
            imageURLs.append(imageURL)
        }
    }
    return imageURLs
}

func parseFirstMention(content: String) -> Int? {
    let protected = MarkdownSource(content)
    return content.matches(of: /##(?<id>\d+)/)
        .first(where: { !protected.protects($0.range) })
        .flatMap { Int($0.id) }
}

extension Floor {
    var collapse: Bool {
        deleted || !fold.isEmpty
    }
}
