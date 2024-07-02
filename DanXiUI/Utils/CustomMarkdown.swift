import DanXiKit
import LaTeXSwiftUI
import MarkdownUI
import SwiftUI
import ViewUtils

public struct CustomMarkdown: View {
    let content: MarkdownContent
    
    let theme = Theme.gitHub
        .paragraph { blockConfiguration in
            let plaintext = blockConfiguration.content.renderPlainText()
            
            if plaintext.contains(/\$(.+)\$/) {
                LaTeX(plaintext)
            } else {
                blockConfiguration.label
                    .relativeLineSpacing(.em(0.18))
            }
        }
        .text {
            ForegroundColor(.primary)
            BackgroundColor(.clear)
            FontSize(UIFont.preferredFont(forTextStyle: .callout).pointSize)
        }
        .link {
            ForegroundColor(Color.link)
        }
    
    public init(_ content: MarkdownContent) {
        self.content = content
    }
    
    public var body: some View {
        Markdown(self.content)
            .markdownTheme(self.theme)
            .markdownImageProvider(CustomImageProvider())
            .markdownInlineImageProvider(ImageProviderWithSticker())
    }
}

struct ImageProviderWithSticker: InlineImageProvider {
    func image(with url: URL, label: String) async throws -> Image {
        guard let sticker = Sticker(rawValue: url.absoluteString) else {
            // This is not a sticker
            throw URLError(.badURL)
        }
        return sticker.image
    }
}

struct CustomImageProvider: ImageProvider {
    func makeImage(url: URL?) -> some View {
        Group {
            if let url {
                if let sticker = Sticker(rawValue: url.absoluteString) {
                    sticker.image
                } else if Proxy.shared.shouldTryProxy, Proxy.shared.outsideCampus {
                    ImageView(url, proxiedURL: Proxy.shared.createProxiedURL(url: url))
                } else {
                    ImageView(url)
                }
            } else {
                EmptyView()
            }
        }
    }
}

extension String {
    /// Convert Treehole-formatted content to basic markdown, stripping images and LaTeX.
    func stripToBasicMarkdown() -> String {
        let text = NSMutableString(string: self)
        
        _ = try? NSRegularExpression(pattern: #"\${1,2}.*?\${1,2}"#, options: .dotMatchesLineSeparators).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: String(localized: "formula_tag", bundle: .module))
        _ = try? NSRegularExpression(pattern: #"!\[.*?\]\(.*?\)"#).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: String(localized: "image_tag", bundle: .module))
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
