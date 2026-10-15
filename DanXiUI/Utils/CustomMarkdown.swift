import DanXiKit
import MarkdownUI
import SwiftUI
import ViewUtils
import Utils

public struct CustomMarkdown: View {
    private let document: MarkdownDocument
    @State private var prepared: PreparedMarkdown?
    @ScaledMetric(relativeTo: .callout) private var fontSize = 16.0

    private var theme: Theme {
        Theme.gitHub
            .paragraph { configuration in
                configuration.label.relativeLineSpacing(.em(0.18))
            }
            .text {
                ForegroundColor(.primary)
                BackgroundColor(.clear)
                FontSize(fontSize)
            }
            .link { ForegroundColor(Color.link) }
    }

    init(_ document: MarkdownDocument) { self.document = document }

    public init(_ source: String) { self.document = MarkdownDocument(source) }

    // Retained for external clients; forum code always supplies the original source.
    public init(_ content: MarkdownContent) { self.document = MarkdownDocument(content.renderMarkdown()) }

    public var body: some View {
        Group {
            if let prepared {
                Markdown(prepared.content)
                    .markdownTheme(theme)
                    .markdownSoftBreakMode(.lineBreak)
                    .markdownImageProvider(CustomImageProvider())
                    .markdownInlineImageProvider(ImageProviderWithSticker())
            }
        }
        .task(id: document.source) {
            let result = await document.prepared.value
            guard !Task.isCancelled else { return }
            prepared = result
        }
    }
}

struct ImageProviderWithSticker: InlineImageProvider {
    func attachment(with url: URL, label: String, fontSize: CGFloat,
                    displayScale: CGFloat, colorScheme: ColorScheme) async throws -> Text {
        if let expression = MathExpression(url: url) {
            do {
                let rendered = try await MathRenderer.shared.render(expression, fontSize: fontSize,
                    displayScale: displayScale, dark: colorScheme == .dark)
                guard let cgImage = rendered.image.cgImage else { return Text(verbatim: expression.source) }
                return Text(Image(cgImage, scale: rendered.image.scale, label: Text(verbatim: expression.source))
                    .renderingMode(.original)).baselineOffset(rendered.baseline)
            } catch {
                return Text(verbatim: expression.source)
            }
        }
        let sticker = try await loadedSticker(with: url)
        return Text(sticker.image)
    }

    func image(with url: URL, label: String) async throws -> Image {
        let sticker = try await loadedSticker(with: url)
        return sticker.image
    }

    private func loadedSticker(with url: URL) async throws -> LoadedImage {
        guard let loadedImage = await MainActor.run(body: { StickerStore.shared.stickerImage[url.absoluteString] }) else {
            // This is not a sticker
            let description = String(localized: "Sticker parse failed.", bundle: .module)
            throw LocatableError(description)
        }
        return loadedImage
    }
}

struct CustomImageProvider: ImageProvider {
    func makeImage(url: URL?) -> some View {
        Group {
            if let url {
                if let expression = MathExpression(url: url) {
                    MathBlockView(expression: expression)
                } else if let loadedImage = StickerStore.shared.stickerImage[url.absoluteString] {
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
    markdown = MarkdownSource(markdown).replacingMath { _ in String(localized: "[Formula]", bundle: .module) }
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
