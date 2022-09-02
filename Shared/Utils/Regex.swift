import Foundation

// implement a regex shortcut, usage: str ~= #"[regex expression]"#
extension String {
    /// If lhs content matches rhs regex, returns true
    static func ~= (lhs: String, rhs: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: rhs) else { return false }
        let range = NSRange(location: 0, length: lhs.utf16.count)
        return regex.firstMatch(in: lhs, options: [], range: range) != nil
    }
    
    func stripToNLProcessableString() -> String {
        let text = NSMutableString(string: self)
        
        _ = try? NSRegularExpression(pattern: #"\${1,2}.*?\${1,2}"#, options: .dotMatchesLineSeparators).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: "[Formula]")
        _ = try? NSRegularExpression(pattern: #"!\[.*?\]\(.*?\)"#).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: "[Image]")
        _ = try? NSRegularExpression(pattern: #"\[.*?\]\(.*?\)"#).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: "[Link]")
        _ = try? NSRegularExpression(pattern: #"(http|https)://.*\W"#).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: "[Link]")
        
        return String(text)
    }
}
