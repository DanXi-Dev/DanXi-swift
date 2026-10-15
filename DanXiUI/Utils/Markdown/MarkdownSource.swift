import Foundation

/// Kept as source until the background parser runs; TeX must never round-trip through Markdown.
struct MathExpression: Codable, Hashable {
    let source: String
    let tex: String
    let display: Bool

    var url: URL {
        let data = try! JSONEncoder().encode(self)
        let token = data.base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
        return URL(string: "\(display ? "markdown-block" : "markdown-inline")://math/\(token)")!
    }

    init(source: String, tex: String, display: Bool) {
        self.source = source
        self.tex = tex
        self.display = display
    }

    init?(url: URL) {
        guard let scheme = url.scheme, ["markdown-inline", "markdown-block"].contains(scheme), url.host == "math" else { return nil }
        var token = String(url.path.dropFirst()).replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        guard token.count <= 100_000 else { return nil }
        token += String(repeating: "=", count: (4 - token.count % 4) % 4)
        guard let data = Data(base64Encoded: token),
              let value = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = value
    }
}

/// A lexical protection pass, before cmark handles the actual Markdown grammar.
/// Code, destinations and TeX are protected from forum mention/image preprocessing.
struct MarkdownSource {
    enum Kind { case code, destination, math(MathExpression) }
    struct Span { let range: Range<String.Index>; let kind: Kind }
    let source: String
    let spans: [Span]

    init(_ source: String) {
        self.source = source
        var spans: [Span] = []
        var i = source.startIndex
        func endOfLine(_ start: String.Index) -> String.Index {
            source[start...].firstIndex(of: "\n") ?? source.endIndex
        }
        func advanceLine(_ end: String.Index) -> String.Index {
            end < source.endIndex ? source.index(after: end) : end
        }
        func has(_ value: String, at index: String.Index) -> Bool { source[index...].hasPrefix(value) }
        func runEnd(_ start: String.Index, character: Character) -> String.Index {
            var end = start
            while end < source.endIndex, source[end] == character { end = source.index(after: end) }
            return end
        }
        while i < source.endIndex {
            let lineStart = i == source.startIndex || source[source.index(before: i)] == "\n"
            if lineStart {
                let lineEnd = endOfLine(i)
                let line = String(source[i..<lineEnd])
                // Permit fenced blocks inside blockquotes and list items.
                if let opener = line.range(of: #"^[ \t]*(?:>[ \t]*)*(?:[-+*] |[0-9]+[.)] )?(`{3,}|~{3,})"#, options: .regularExpression) {
                    let prefix = String(line[opener])
                    let character: Character = prefix.last!
                    let count = prefix.reversed().prefix(while: { $0 == character }).count
                    var next = advanceLine(lineEnd)
                    var end = source.endIndex
                    while next < source.endIndex {
                        let eol = endOfLine(next)
                        let candidate = String(source[next..<eol])
                        let pattern = "^[ \\t]*(?:>[ \\t]*)*" + String(repeating: String(character), count: count) + String(character) + "*[ \\t]*$"
                        if candidate.range(of: pattern, options: .regularExpression) != nil {
                            end = advanceLine(eol)
                            break
                        }
                        next = advanceLine(eol)
                    }
                    spans.append(Span(range: i..<end, kind: .code)); i = end; continue
                }
                if line.hasPrefix("    ") || line.hasPrefix("\t") {
                    spans.append(Span(range: i..<lineEnd, kind: .code)); i = advanceLine(lineEnd); continue
                }
                if line.range(of: #"^ {0,3}\[[^\]]+\]:"#, options: .regularExpression) != nil {
                    spans.append(Span(range: i..<lineEnd, kind: .destination)); i = advanceLine(lineEnd); continue
                }
            }
            if source[i] == "`" {
                let openingEnd = runEnd(i, character: "`")
                let count = source.distance(from: i, to: openingEnd)
                var next = openingEnd
                var closing: String.Index?
                while next < source.endIndex {
                    if source[next] == "`" {
                        let end = runEnd(next, character: "`")
                        if source.distance(from: next, to: end) == count { closing = end; break }
                        next = end
                    } else { next = source.index(after: next) }
                }
                if let closing { spans.append(Span(range: i..<closing, kind: .code)); i = closing; continue }
                i = openingEnd; continue
            }
            // Image alt text and image URLs are data, not a nested formula document.
            if has("![", at: i) {
                var next = source.index(i, offsetBy: 2)
                var depth = 1
                while next < source.endIndex, depth > 0 {
                    let char = source[next]
                    next = source.index(after: next)
                    if char == "\\", next < source.endIndex { next = source.index(after: next); continue }
                    if char == "[" { depth += 1 }
                    if char == "]" { depth -= 1 }
                }
                if depth == 0, next < source.endIndex, source[next] == "(" || source[next] == "[" {
                    let opening = source[next]
                    let closing: Character = opening == "(" ? ")" : "]"
                    depth = 1
                    next = source.index(after: next)
                    while next < source.endIndex, depth > 0 {
                        let char = source[next]
                        next = source.index(after: next)
                        if char == "\\", next < source.endIndex { next = source.index(after: next); continue }
                        if char == opening { depth += 1 }
                        if char == closing { depth -= 1 }
                    }
                }
                if depth == 0 {
                    spans.append(Span(range: i..<next, kind: .destination)); i = next; continue
                }
            }
            if has("https://", at: i) || has("http://", at: i) {
                var next = i
                while next < source.endIndex, !source[next].isWhitespace, source[next] != ">" {
                    next = source.index(after: next)
                }
                spans.append(Span(range: i..<next, kind: .destination)); i = next; continue
            }
            if has("](", at: i) {
                var next = source.index(i, offsetBy: 2)
                var depth = 1
                while next < source.endIndex, depth > 0 {
                    let char = source[next]
                    next = source.index(after: next)
                    if char == "\\", next < source.endIndex { next = source.index(after: next); continue }
                    if char == "(" { depth += 1 }
                    if char == ")" { depth -= 1 }
                }
                spans.append(Span(range: i..<next, kind: .destination)); i = next; continue
            }
            if source[i] == "<", let end = source[i...].firstIndex(of: ">") {
                let next = source.index(after: end)
                spans.append(Span(range: i..<next, kind: .destination)); i = next; continue
            }
            let delimiter: (String, String, Bool)?
            if has("$$", at: i) { delimiter = ("$$", "$$", true) }
            else if has("$", at: i) { delimiter = ("$", "$", false) }
            else if has(#"\("#, at: i) { delimiter = (#"\("#, #"\)"#, false) }
            else if has(#"\["#, at: i) { delimiter = (#"\["#, #"\]"#, true) }
            else { delimiter = nil }
            if let (opening, closing, display) = delimiter {
                let start = source.index(i, offsetBy: opening.count)
                var next = start
                var end: String.Index?
                let dollarInline = opening == "$"
                if !(dollarInline && (start == source.endIndex || source[start].isWhitespace)) {
                    while next < source.endIndex {
                        if !display && source[next] == "\n" { break }
                        if has(closing, at: next) {
                            let after = source.index(next, offsetBy: closing.count)
                            let valid = !dollarInline || (next > start && !source[source.index(before: next)].isWhitespace && (after == source.endIndex || !source[after].isNumber))
                            if valid { end = after }
                            break
                        }
                        if source[next] == "\\" {
                            next = source.index(after: next)
                            if next < source.endIndex { next = source.index(after: next) }
                        } else { next = source.index(after: next) }
                    }
                }
                if let end {
                    let bodyEnd = source.index(end, offsetBy: -closing.count)
                    var tex = String(source[start..<bodyEnd])
                    if display {
                        let lineStart = source[..<i].lastIndex(of: "\n").map { source.index(after: $0) } ?? source.startIndex
                        let prefix = String(source[lineStart..<i])
                        if prefix.range(of: #"^ {0,3}(?:>[ \t]*)+$"#, options: .regularExpression) != nil {
                            tex = tex.components(separatedBy: "\n").enumerated().map { index, line in
                                index > 0 && line.hasPrefix(prefix) ? String(line.dropFirst(prefix.count)) : line
                            }.joined(separator: "\n")
                        }
                    }
                    let expression = MathExpression(source: String(source[i..<end]), tex: tex, display: display)
                    spans.append(Span(range: i..<end, kind: .math(expression))); i = end; continue
                }
            }
            if source[i] == "\\" {
                i = source.index(after: i)
                if i < source.endIndex { i = source.index(after: i) }
            } else { i = source.index(after: i) }
        }
        self.spans = spans
    }

    var expressions: [MathExpression] {
        spans.compactMap { if case .math(let expression) = $0.kind { return expression }; return nil }
    }

    func protects(_ range: Range<String.Index>, destinations: Bool = true) -> Bool {
        spans.contains { span in
            if !destinations, case .destination = span.kind { return false }
            return span.range.overlaps(range)
        }
    }

    func replacingMath(_ replacement: (MathExpression) -> String) -> String {
        var result = source
        for span in spans.reversed() {
            if case .math(let expression) = span.kind { result.replaceSubrange(span.range, with: replacement(expression)) }
        }
        return result
    }

    var markdown: String {
        replacingMath { expression in
            let alt = expression.source.replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "[", with: "\\[").replacingOccurrences(of: "]", with: "\\]")
                .replacingOccurrences(of: "|", with: "\\|")
                .replacingOccurrences(of: "*", with: "\\*")
                .replacingOccurrences(of: "_", with: "\\_")
                .replacingOccurrences(of: "`", with: "\\`")
                .replacingOccurrences(of: "\n", with: " ")
            return "![\(alt)](\(expression.url.absoluteString))"
        }
    }
}
