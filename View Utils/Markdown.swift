import SwiftUI
import MarkdownUI
import LaTeXSwiftUI

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
            BackgroundColor(.clear)
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

struct CustomImageProvider: ImageProvider {
    func makeImage(url: URL?) -> some View {
        Group {
            if let url = url {
                ImageView(url)
            } else {
                EmptyView()
            }
        }
    }
}
