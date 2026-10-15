import SwiftUI

struct InlineText: View {
  @Environment(\.inlineImageProvider) private var inlineImageProvider
  @Environment(\.baseURL) private var baseURL
  @Environment(\.imageBaseURL) private var imageBaseURL
  @Environment(\.softBreakMode) private var softBreakMode
  @Environment(\.theme) private var theme
  @Environment(\.displayScale) private var displayScale
  @Environment(\.colorScheme) private var colorScheme

  @State private var inlineImages: [String: Text] = [:]
  private let inlines: [InlineNode]

  init(_ inlines: [InlineNode]) { self.inlines = inlines }

  private struct Request: Hashable {
    let inlines: [InlineNode]
    let fontSize: CGFloat
    let displayScale: CGFloat
    let colorScheme: ColorScheme
  }

  var body: some View {
    TextStyleAttributesReader { attributes in
      let request = Request(inlines: inlines,
                            fontSize: attributes.fontProperties?.scaledSize ?? FontProperties.defaultSize,
                            displayScale: displayScale, colorScheme: colorScheme)
      self.inlines.renderText(
        baseURL: self.baseURL,
        textStyles: .init(code: self.theme.code, emphasis: self.theme.emphasis,
                         strong: self.theme.strong, strikethrough: self.theme.strikethrough,
                         link: self.theme.link),
        images: self.inlineImages,
        softBreakMode: self.softBreakMode,
        attributes: attributes
      )
      .task(id: request) {
        // Each attachment fails independently; one missing sticker must not erase math.
        let images = await loadInlineImages(request)
        guard !Task.isCancelled else { return }
        self.inlineImages = images
      }
    }
  }

  private func loadInlineImages(_ request: Request) async -> [String: Text] {
    func collect(_ nodes: [InlineNode]) -> [RawImageData] {
      nodes.flatMap { node in
        if case .image = node, let data = node.imageData { return [data] }
        return collect(node.children)
      }
    }
    let images = Set(collect(request.inlines))
    let provider = self.inlineImageProvider
    return await withTaskGroup(of: (String, Text)?.self) { group in
      for image in images {
        guard let url = URL(string: image.source, relativeTo: self.imageBaseURL) else { continue }
        group.addTask {
          guard let text = try? await provider.attachment(
            with: url, label: image.alt, fontSize: request.fontSize,
            displayScale: request.displayScale, colorScheme: request.colorScheme
          ) else { return nil }
          return (image.source, text)
        }
      }
      var result: [String: Text] = [:]
      for await item in group {
        if let (source, text) = item { result[source] = text }
      }
      return result
    }
  }
}
