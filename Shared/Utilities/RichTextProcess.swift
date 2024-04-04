import Foundation

extension String {
    /// Convert Treehole-formatted content to basic markdown, stripping images and LaTeX.
    func stripToBasicMarkdown() -> String {
        let text = NSMutableString(string: self)
        
        _ = try? NSRegularExpression(pattern: #"\${1,2}.*?\${1,2}"#, options: .dotMatchesLineSeparators).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: NSLocalizedString("formula_tag", comment: "Formula Tag"))
        _ = try? NSRegularExpression(pattern: #"!\[.*?\]\(.*?\)"#).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: NSLocalizedString("image_tag", comment: "Image Tag"))
//        _ = try? NSRegularExpression(pattern: #"#{1,2}[0-9]+\s*"#).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: "")
        
        return String(text)
    }
    
    /// Convert `String` to `AttributedString` using Markdown syntax, stripping images and LaTeX.
    func inlineAttributed() -> AttributedString {
        let content = self.stripToBasicMarkdown()
        if let attributedString = try? AttributedString(markdown: content) {
            return attributedString
        }
        return AttributedString(content)
    }
    
    /// Replace elements like formula and images to tags for ML to process.
    func stripToNLProcessableString() -> String {
        let text = NSMutableString(string: self)
        
        _ = try? NSRegularExpression(pattern: #"\${1,2}.*?\${1,2}"#, options: .dotMatchesLineSeparators).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: "[Formula]")
        _ = try? NSRegularExpression(pattern: #"!\[.*?\]\(.*?\)"#).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: "[Image]")
        _ = try? NSRegularExpression(pattern: #"\[.*?\]\(.*?\)"#).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: "[Link]")
        _ = try? NSRegularExpression(pattern: #"(http|https)://.*\W"#).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: "[Link]")
        
        return String(text)
    }
}
