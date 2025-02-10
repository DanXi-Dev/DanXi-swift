import DanXiKit
import LaTeXSwiftUI
import MarkdownUI
import SwiftUI
import ViewUtils
import Utils

public struct CustomMarkdown: View {
    private let content: MarkdownContent
    
    private let theme = Theme.gitHub
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
            let description = String(localized: "Sticker parse failed.", bundle: .module)
            throw LocatableError(description)
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
    /// Convert Treehole-formatted content to basic markdown, stripping images, stickers and LaTeX.
    func stripToBasicMarkdown() -> String {
        let text = NSMutableString(string: self)
        
        _ = try? NSRegularExpression(pattern: #"\${1,2}.*?\${1,2}"#, options: .dotMatchesLineSeparators).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: String(localized: "formula_tag", bundle: .module))
        // Replace Stickers (e.g., ![](dx_cate))
        let stickerPatterns = Sticker.allCases.map { $0.rawValue }.joined(separator: "|")
        _ = try? NSRegularExpression(pattern: #"!\[\]\((\#(stickerPatterns))\)"#).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: String(localized: "sticker_tag", bundle: .module))
        // Replace Images
        _ = try? NSRegularExpression(pattern: #"!\[.*?\]\(.*?\)"#).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: String(localized: "image_tag", bundle: .module))
//        _ = try? NSRegularExpression(pattern: #"#{1,2}[0-9]+\s*"#).replaceMatches(in: text, range: NSRange(location: 0, length: text.length), withTemplate: "")
        
        return String(text)
    }
    
    /// Convert `String` to `AttributedString` using Markdown syntax, stripping images stickers and LaTeX.
    func inlineAttributed() -> AttributedString {
        let content = self.stripToBasicMarkdown()
        if let attributedString = try? AttributedString(markdown: content) {
            return attributedString
        }
        return AttributedString(content)
    }
}
