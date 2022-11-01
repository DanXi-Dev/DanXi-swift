import SwiftUI
import Markdown
import CachedAsyncImage

/// A view that renders Markdown content.
struct MarkdownView: View {
    let markup: Markup
    
    /// Creates an instance from Markdown string.
    init(_ content: String) {
        self.markup = Document(parsing: content)
    }
    
    /// Creates an instance from parsed `Markup` element.
    init(_ markup: Markup) {
        self.markup = markup
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(markup.childNodes()) { node in
                switch node.markup {
                    
                case let heading as Heading:
                    headingRenderer(heading)
                case let codeBlock as CodeBlock:
                    codeBlockRenderer(codeBlock)
                case _ as ThematicBreak:
                    Divider()
                    
                case let paragraph as Paragraph:
                    paragraphRenderer(paragraph)
                    
                case let orderedList as OrderedList:
                    orderedListRenderer(orderedList)
                    
                case let unorderedList as UnorderedList:
                    unorderedListRenderer(unorderedList)
                    
                case let quote as BlockQuote:
                    quoteRenderer(quote)
                    
                default:
                    EmptyView()
                }
            }
        }
    }
    
    private func headingRenderer(_ heading: Heading) -> some View {
        let font: Font
        switch heading.level {
        case 1:
            font = .largeTitle
        case 2:
            font = .title
        case 3:
            font = .title2
        case 4:
            font = .title3
        case 5:
            font = .body
        default:
            font = .callout
        }
        
        return TextView(heading.plainText)
            .font(font)
            .fontWeight(.bold)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func codeBlockRenderer(_ codeBlock: CodeBlock) -> some View {
        return ScrollView(.horizontal, showsIndicators: false) {
            TextView(codeBlock.code)
                .font(.callout.monospaced())
        }
    }
    
    private func orderedListRenderer(_ orderedList: OrderedList) -> some View {
        return VStack(alignment: .leading) {
            ForEach(Array(orderedList.items().enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 2.0) {
                    TextView("\(index + 1).")
                        .frame(width: 20)
                    MarkdownView(item.markup)
                }
            }
        }
        .font(.callout)
    }
    
    private func unorderedListRenderer(_ unorderedList: UnorderedList) -> some View {
        return VStack(alignment: .leading) {
            ForEach(Array(unorderedList.items().enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 2.0) {
                    TextView("·")
                        .bold()
                        .frame(width: 20)
                    MarkdownView(item.markup)
                }
            }
        }
    }
    
    private func quoteRenderer(_ quote: BlockQuote) -> some View {
        return VStack(alignment: .leading, spacing: 10) {
            ForEach(quote.childNodes()) { node in
                switch node.markup {
                case let heading as Heading:
                    headingRenderer(heading)
                    
                case let codeBlock as CodeBlock:
                    codeBlockRenderer(codeBlock)
                    
                case _ as ThematicBreak:
                    Divider()
                    
                case let paragraph as Paragraph:
                    paragraphRenderer(paragraph)
                    
                case let orderedList as OrderedList:
                    orderedListRenderer(orderedList)
                    
                case let unorderedList as UnorderedList:
                    unorderedListRenderer(unorderedList)
                    
                default:
                    MarkdownView(node.markup)
                }
            }
        }
        .padding(.leading, 10)
        .overlay(Rectangle().frame(width: 3, height: nil, alignment: .leading).foregroundColor(Color.secondary.opacity(0.5)), alignment: .leading)
        .foregroundColor(.secondary)
    }
    
    private func paragraphRenderer(_ paragraph: Paragraph) -> some View {
        enum ParagraphElement: Identifiable {
            case paragraph(content: AttributedString)
            case image(url: URL)
            
            var id: UUID {
                UUID()
            }
        }
        
        let content = paragraph.detachedFromParent.format()
        var elements: [ParagraphElement] = []
        
        if let attributedContent = try? AttributedString(markdown: content, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            var leadingBorder = attributedContent.startIndex
            for run in attributedContent.runs {
                if let url = run.imageURL {
                    let leadingSegment = attributedContent[leadingBorder..<run.range.lowerBound]
                    elements.append(.paragraph(content: AttributedString(leadingSegment)))
                    elements.append(.image(url: url))
                    leadingBorder = run.range.upperBound
                }
            }
            if leadingBorder != attributedContent.endIndex {
                let trailingSegment = attributedContent[leadingBorder..<attributedContent.endIndex]
                elements.append(.paragraph(content: AttributedString(trailingSegment)))
            }
        } else {
            elements.append(.paragraph(content: AttributedString(content)))
        }
        
        return VStack(alignment: .leading, spacing: 5) {
            ForEach(elements) { element in
                switch(element) {
                case .paragraph(let text):
                    TextView(text)
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                case .image(let url):
                    HStack {
                        Spacer()
                        CachedAsyncImage(url: url, urlCache: .imageCache) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } else if phase.error != nil {
                                Color.gray.opacity(0.1)
                                    .overlay { Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red) }
                            } else {
                                Color.gray.opacity(0.1)
                                    .overlay { ProgressView() }
                            }
                        }
                        .frame(width: 300, height: 300)
                        Spacer()
                    }
                }
            }
        }
    }
}

extension URLCache {
    static let imageCache = URLCache(memoryCapacity: 512 * 1000 * 1000, // 512 MB
                                     diskCapacity: 1000 * 1000 * 1000) // 1 GB
}

extension Markup {
    fileprivate func childNodes() -> [MarkupNode] {
        return self.children.map { markup in
            MarkupNode(markup)
        }
    }
}

extension ListItemContainer {
    fileprivate func items() -> [MarkupNode] {
        return self.listItems.map { item in
            MarkupNode(item)
        }
    }
}

/// Struct holding `Markup` element, enabling random access and identifiable support for `ForEach`.
fileprivate struct MarkupNode: Identifiable {
    let id = UUID()
    let markup: Markup
    
    init(_ markup: Markup) {
        self.markup = markup
    }
}
