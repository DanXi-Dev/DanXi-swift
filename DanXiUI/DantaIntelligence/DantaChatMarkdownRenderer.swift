import DanXiKit
import LaTeXSwiftUI
import MarkdownUI
import SwiftUI
import UIKit

@available(iOS 18.0, *)
struct DantaMarkdownBubbleText: View {
    let text: String
    let isUser: Bool

    var body: some View {
        if isUser {
            DantaChatMarkdownRenderer(text: text, isUser: true)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(DantaIntelligenceTextProcessing.assistantSegments(from: text).enumerated()), id: \.offset) { _, text in
                    DantaChatMarkdownRenderer(text: text, isUser: false)
                }
            }
        }
    }
}

@available(iOS 18.0, *)
private struct DantaChatMarkdownRenderer: View {
    let text: String
    let isUser: Bool
    private var textColor: Color { isUser ? .white : .primary }

    var body: some View {
        let processed = DantaIntelligenceTextProcessing.preprocessMarkdown(self.text)
        VStack(alignment: .leading, spacing: 10) {
            Markdown(processed.cleaned)
                .markdownTheme(theme)
                .markdownSoftBreakMode(.lineBreak)
                .font(.body)
                .foregroundStyle(self.textColor)
                .tint(isUser ? self.textColor : .accentColor)

            if !processed.images.isEmpty {
                DantaInlineImageList(images: processed.images)
            }
        }
    }
    private var theme: Theme {
        return Theme.gitHub
            .paragraph { configuration in
                let plaintext = configuration.content.renderPlainText()
                VStack(alignment: .leading, spacing: 0) {
                    if plaintext.range(of: #"\${1,2}[\s\S]+?\${1,2}"#, options: .regularExpression) != nil {
                        LaTeX(plaintext)
                            .foregroundStyle(textColor)
                    } else {
                        configuration.label
                            .fixedSize(horizontal: false, vertical: true)
                            .relativeLineSpacing(.em(0.22))
                    }
                }
                .markdownMargin(top: 0, bottom: 12)
            }
            .text {
                ForegroundColor(textColor)
                BackgroundColor(.clear)
            }
            .link {
                ForegroundColor(isUser ? textColor : .accentColor)
            }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(.em(0.9))
                BackgroundColor(textColor.opacity(isUser ? 0.18 : 0.08))
            }
    }
}

@available(iOS 18.0, *)
private struct DantaInlineImageList: View {
    let images: [DantaIntelligenceInlineImage]

    var body: some View {
        ForEach(images, id: \.id) { item in
            if let image = item.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    }
            } else {
                Text(item.label.isEmpty ? "Image" : item.label)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
