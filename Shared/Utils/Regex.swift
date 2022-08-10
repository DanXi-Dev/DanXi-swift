import Foundation

// implement a regex shortcut, usage: str ~= #"[regex expression]"#
extension String {
    /// If lhs content matches rhs regex, returns true
    static func ~= (lhs: String, rhs: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: rhs) else { return false }
        let range = NSRange(location: 0, length: lhs.utf16.count)
        return regex.firstMatch(in: lhs, options: [], range: range) != nil
    }
    
    /// Convert Treehole-formatted content to basic markdown, stripping images and latex
    func stripToBasicMarkdown() -> String {
        let text = NSMutableString(string: self)
        
        _ = try? NSRegularExpression(pattern: #"\$\$.*?\$\$"#, options: .dotMatchesLineSeparators).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: NSLocalizedString("formula_tag", comment: "Formula Tag"))
        
        _ = try? NSRegularExpression(pattern: #"!\[.*?\]\(.*?\)"#, options: .dotMatchesLineSeparators).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: NSLocalizedString("image_tag", comment: "Image Tag"))
        
        return String(text)
    }
}
