import DanXiKit
import MarkdownUI
import SwiftUI
import ViewUtils
import Utils

public struct CustomMarkdown: View {
    private let document: MarkdownDocument
    @State private var prepared: DisplayContent?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    @ScaledMetric(relativeTo: .callout) private var fontSize = 16.0

    private struct Request: Hashable {
        let source: String
        let fontSize: CGFloat
        let displayScale: CGFloat
        let dark: Bool
    }

    private struct DisplayContent {
        let request: Request
        let markdown: PreparedMarkdown
        let math: [MathExpression: RenderedMath]
    }

    private var request: Request {
        Request(source: document.source, fontSize: fontSize,
                displayScale: displayScale, dark: colorScheme == .dark)
    }

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
        VStack(alignment: .leading, spacing: 0) {
            if let prepared, prepared.request == request {
                Markdown(prepared.markdown.content)
                    .markdownTheme(theme)
                    .markdownSoftBreakMode(.lineBreak)
                    .markdownImageProvider(CustomImageProvider(math: prepared.math))
                    .markdownInlineImageProvider(ImageProviderWithSticker(math: prepared.math, renderedFontSize: prepared.request.fontSize))
            }
        }
        .task(id: request) {
            let request = self.request
            guard !Task.isCancelled else { return }
            prepared = nil
            let result = await document.prepared.value
            do {
                try Task.checkCancellation()
                let math = try await MathRenderer.shared.renderAll(result.expressions,
                    fontSize: request.fontSize, displayScale: request.displayScale, dark: request.dark)
                try Task.checkCancellation()
                prepared = DisplayContent(request: request, markdown: result, math: math)
            } catch is CancellationError {
                return
            } catch {
                assertionFailure("Unexpected formula preparation error: \(error)")
            }
        }
    }
}

struct ImageProviderWithSticker: InlineImageProvider {
    let math: [MathExpression: RenderedMath]
    let renderedFontSize: CGFloat

    func preparedAttachment(with url: URL, label: String, fontSize: CGFloat) -> Text? {
        guard let expression = MathExpression(url: url) else { return nil }
        guard let rendered = math[expression], let cgImage = rendered.image.cgImage else {
            return Text(verbatim: expression.source)
        }
        // Headings may use a different font size; scale the prepared attachment without rerasterizing.
        let ratio = fontSize / renderedFontSize
        return Text(Image(cgImage, scale: rendered.image.scale / ratio,
                          label: Text(verbatim: expression.source)).renderingMode(.original))
            .baselineOffset(rendered.baseline * ratio)
    }

    func attachment(with url: URL, label: String, fontSize: CGFloat,
                    displayScale: CGFloat, colorScheme: ColorScheme) async throws -> Text {
        if let prepared = preparedAttachment(with: url, label: label, fontSize: fontSize) {
            return prepared
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
    let math: [MathExpression: RenderedMath]

    func makeImage(url: URL?) -> some View {
        Group {
            if let url {
                if let expression = MathExpression(url: url) {
                    MathBlockView(expression: expression, rendered: math[expression])
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
