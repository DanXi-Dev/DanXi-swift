import SwiftUI
import MarkdownUI
import LaTeXSwiftUI
import ViewUtils

public struct CustomMarkdown: View {
    let content: String
    
    let theme = Theme.gitHub
        .paragraph { blockConfiguration in
            let plaintext = blockConfiguration.content.renderPlainText()
            
            if plaintext.contains(/\$(.+)\$/) {
                LaTeX(plaintext)
            } else {
                blockConfiguration.label
            }
        }
        .text {
            ForegroundColor(.primary)
            BackgroundColor(.clear)
            FontSize(UIFont.preferredFont(forTextStyle: .subheadline).pointSize)
        }
        .link {
            ForegroundColor(Color.link)
        }
    
    
    public init(_ content: String) {
        self.content = content
    }
    
    public var body: some View {
        Markdown(content)
            .markdownTheme(theme)
            .markdownImageProvider(CustomImageProvider())
    }
}

public struct CustomImageProvider: ImageProvider {
    public func makeImage(url: URL?) -> some View {
        Group {
            if let url = url {
                if let sticker = THSticker(rawValue: url.absoluteString) {
                    sticker.image
                } else {
                    ImageView(url)
                }
            } else {
                EmptyView()
            }
        }
    }
}
