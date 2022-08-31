import SwiftUI
import Markdown

extension Markup {
    func childNodes() -> [MarkupNode] {
        return self.children.map { markup in
            MarkupNode(markup)
        }
    }
}

extension ListItemContainer {
    func items() -> [MarkupNode] {
        return self.listItems.map { item in
            MarkupNode(item)
        }
    }
}

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}

struct MarkupNode: Identifiable {
    let id = UUID()
    let markup: Markup
    
    init(_ markup: Markup) {
        self.markup = markup
    }
}

struct MarkdownView: View {
    let markup: Markup
    
    init(_ content: String) {
        self.markup = Document(parsing: content)
    }
    
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
                    SwiftUIText("NOT SUPPORTED ELEMENT: \(String(describing: type(of: markup).self))")
                }
            }
        }
    }
    
    private func headingRenderer(_ heading: Heading) -> some View {
        let font: Font
        switch heading.level {
        case 1:
            font = .system(size: 28)
        case 2:
            font = .system(size: 22)
        case 3:
            font = .system(size: 20)
        case 4:
            font = .system(size: 18)
        case 5:
            font = .system(size: 17)
        default:
            font = .system(size: 16)
        }
        
        return SwiftUIText(heading.plainText)
            .font(font)
            .fontWeight(.bold)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func paragraphRenderer(_ paragraph: Paragraph) -> some View {
        let content = paragraph
                        .format()
                        .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let attributedContent = try? AttributedString(markdown: content, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        
        return SwiftUIText(attributedContent ?? AttributedString(content))
            .font(.system(size: 16))
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func codeBlockRenderer(_ codeBlock: CodeBlock) -> some View {
        return SwiftUIText(codeBlock.code)
            .font(.system(size: 16, design: .monospaced))
    }
    
    private func orderedListRenderer(_ orderedList: OrderedList) -> some View {
        return VStack(alignment: .leading) {
            ForEach(Array(orderedList.items().enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 2.0) {
                    SwiftUIText("\(index + 1).")
                        .frame(width: 20)
                    MarkdownView(item.markup)
                }
            }
        }
        .font(.system(size: 16))
    }
    
    private func unorderedListRenderer(_ unorderedList: UnorderedList) -> some View {
        return VStack(alignment: .leading) {
            ForEach(Array(unorderedList.items().enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 2.0) {
                    SwiftUIText("·")
                        .bold()
                        .frame(width: 20)
                        .textSelection(.disabled)
                    MarkdownView(item.markup)
                }
            }
        }
    }
    
    private func quoteRenderer(_ quote: BlockQuote) -> some View {
        return VStack(alignment: .leading, spacing: 10) {
            ForEach(quote.childNodes()) { node in
                MarkdownView(node.markup)
            }
        }
        .padding(.leading, 10)
        .overlay(Rectangle().frame(width: 3, height: nil, alignment: .leading).foregroundColor(Color.secondary.opacity(0.5)), alignment: .leading)
        .foregroundColor(.secondary)
    }
}
