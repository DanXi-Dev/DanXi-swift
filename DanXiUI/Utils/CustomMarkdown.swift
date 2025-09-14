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
            .markdownSoftBreakMode(.lineBreak)
            .markdownImageProvider(CustomImageProvider())
            .markdownInlineImageProvider(ImageProviderWithSticker())
    }
}

struct ImageProviderWithSticker: InlineImageProvider {
    func image(with url: URL, label: String) async throws -> Image {
        guard let loadedImage = StickerStore.shared.stickerImage[url.absoluteString] else {
            // This is not a sticker
            let description = String(localized: "Sticker parse failed.", bundle: .module)
            throw LocatableError(description)
        }
        return loadedImage.image
    }
}

struct CustomImageProvider: ImageProvider {
    func makeImage(url: URL?) -> some View {
        Group {
            if let url {
                if let loadedImage = StickerStore.shared.stickerImage[url.absoluteString] {
                    loadedImage.image
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


func replaceMarkdownTags(_ content: String) -> String {
    var markdown = content
    markdown.replace(/\${1,2}[\s\S]*?\${1,2}/, with: String(localized: "[Formula]", bundle: .module))
    markdown.replace(/!\[.*?\]\((?<link>.*?)\)/) { match in
        if StickerStore.shared.stickerSet.contains(String(match.link)) {
            return String(localized: "[Sticker]", bundle: .module)
        } else {
            return String(localized: "[Image]", bundle: .module)
        }
    }
    
    return markdown
}

func inlineAttributed(_ content: String, multiline: Bool = false) -> AttributedString {
    let replacedContent = replaceMarkdownTags(content)
    var processedContent = replacedContent
    
    if multiline {
        let lines = replacedContent.split(separator: "\n")
        let nonEmptyLines = lines.filter { line in
            !line.trimmingCharacters(in: .whitespaces).isEmpty
        }
        processedContent = nonEmptyLines.joined(separator: "\n")
    }
    
    let options = if multiline {
        AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    } else {
        AttributedString.MarkdownParsingOptions()
    }
    
    if let attributedString = try? AttributedString(markdown: processedContent, options: options) {
        return attributedString
    }
    return AttributedString(processedContent)
}
