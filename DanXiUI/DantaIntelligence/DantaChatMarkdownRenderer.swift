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
            DantaChatMarkdownRenderer(
                text: text,
                context: .user,
                variant: .standard,
                font: .body,
                textColor: .white)
        } else {
            DantaAssistantMarkdownBody(
                text: text,
                markdownVariant: .standard,
                includesThinking: false,
                font: .body,
                textColor: .primary)
        }
    }
}

@available(iOS 18.0, *)
private struct DantaChatMarkdownRenderer: View {
    enum Context {
        case user
        case assistant
    }

    let text: String
    let context: Context
    let variant: DantaChatMarkdownVariant
    let font: Font
    let textColor: Color

    var body: some View {
        let processed = DantaIntelligenceTextProcessing.preprocessMarkdown(self.text)
        VStack(alignment: .leading, spacing: 10) {
            Markdown(processed.cleaned)
                .markdownTheme(DantaChatMarkdownStyle.theme(
                    variant: self.variant,
                    context: self.context,
                    textColor: self.textColor))
                .markdownSoftBreakMode(.lineBreak)
                .font(self.font)
                .foregroundStyle(self.textColor)
                .tint(self.context == .user ? self.textColor : .accentColor)

            if !processed.images.isEmpty {
                DantaInlineImageList(images: processed.images)
            }
        }
    }
}

@available(iOS 18.0, *)
private struct DantaAssistantMarkdownBody: View {
    let text: String
    let markdownVariant: DantaChatMarkdownVariant
    let includesThinking: Bool
    let font: Font
    let textColor: Color

    var body: some View {
        let segments = DantaIntelligenceTextProcessing.assistantSegments(
            from: self.text,
            includeThinking: self.includesThinking)
        VStack(alignment: .leading, spacing: 10) {
            ForEach(segments) { segment in
                let font = segment.kind == .thinking ? self.font.italic() : self.font
                DantaChatMarkdownRenderer(
                    text: segment.text,
                    context: .assistant,
                    variant: self.markdownVariant,
                    font: font,
                    textColor: self.textColor)
            }
        }
    }
}

private enum DantaChatMarkdownVariant: String, CaseIterable, Sendable {
    case standard
    case compact
}

@available(iOS 18.0, *)
private enum DantaChatMarkdownStyle {
    static func theme(
        variant: DantaChatMarkdownVariant,
        context: DantaChatMarkdownRenderer.Context,
        textColor: Color
    ) -> Theme {
        let linkColor: Color = context == .user ? textColor : .accentColor
        let codeScale: Double = variant == .compact ? 0.85 : 0.9

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
                            .relativeLineSpacing(.em(variant == .compact ? 0.16 : 0.22))
                    }
                }
                .markdownMargin(top: 0, bottom: variant == .compact ? 8 : 12)
            }
            .text {
                ForegroundColor(textColor)
                BackgroundColor(.clear)
            }
            .link {
                ForegroundColor(linkColor)
            }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(.em(codeScale))
                BackgroundColor(textColor.opacity(context == .user ? 0.18 : 0.08))
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
