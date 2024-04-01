import SwiftUI
import Markdown
import CachedAsyncImage
import LaTeXSwiftUI

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
    
    func customParagraph(renderer: @escaping (AttributedString) -> some View) -> some View {
        return self.environment(\.customParagraph) { text in
            AnyView(renderer(text))
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(markup.childNodes()) { node in
                switch node.markup {
                    
                case let heading as Heading:
                    HeadingView(heading)
                case let codeBlock as CodeBlock:
                    CodeBlockView(codeBlock: codeBlock)
                case _ as ThematicBreak:
                    Divider()
                case let paragraph as Paragraph:
                    ParagraphView(paragraph)
                case let orderedList as OrderedList:
                    OrderedListView(orderedList: orderedList)
                case let unorderedList as UnorderedList:
                    UnorderedListView(unorderedList: unorderedList)
                case let quote as BlockQuote:
                    QuoteView(quote: quote)
                case let table as Markdown.Table:
                    TableView(table: table)
                default:
                    Label("Not Supported: \(String(describing: type(of: node.markup)))", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }
            }
        }
    }
}

// MARK: Subview

fileprivate struct HeadingView: View {
    private let content: String
    private let font: Font
    
    init(_ heading: Heading) {
        content = heading.plainText
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
    }
    
    var body: some View {
        SwiftUI.Text(content)
            .font(font)
            .fontWeight(.bold)
            .fixedSize(horizontal: false, vertical: true)
    }
}

fileprivate struct CodeBlockView: View {
    let codeBlock: CodeBlock
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            SwiftUI.Text(codeBlock.code)
                .font(.callout.monospaced())
        }
    }
}

fileprivate struct OrderedListView: View {
    let orderedList: OrderedList
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(Array(orderedList.items().enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 2.0) {
                    SwiftUI.Text("\(index + Int(orderedList.startIndex)).")
                        .frame(width: 20)
                    MarkdownView(item.markup)
                }
            }
        }
        .font(.callout)
    }
}

fileprivate struct UnorderedListView: View {
    let unorderedList: UnorderedList
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(Array(unorderedList.items().enumerated()), id: \.offset) { index, item in
                let listItem = item.markup as! ListItem
                HStack(alignment: .top, spacing: 2.0) {
                    if let checkbox = listItem.checkbox {
                        Image(systemName: checkbox == .checked ? "checkmark.circle.fill" : "circle")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                            .frame(width: 30)
                            .padding(.top, 4)
                    } else {
                        SwiftUI.Text("·")
                            .bold()
                            .frame(width: 20)
                    }
                    MarkdownView(listItem)
                }
            }
        }
    }
}

fileprivate struct QuoteView: View {
    let quote: BlockQuote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(quote.childNodes()) { node in
                switch node.markup {
                case let heading as Heading:
                    HeadingView(heading)
                case let codeBlock as CodeBlock:
                    CodeBlockView(codeBlock: codeBlock)
                case _ as ThematicBreak:
                    Divider()
                case let paragraph as Paragraph:
                    ParagraphView(paragraph)
                case let orderedList as OrderedList:
                    OrderedListView(orderedList: orderedList)
                case let unorderedList as UnorderedList:
                    UnorderedListView(unorderedList: unorderedList)
                case let quote as BlockQuote:
                    AnyView(QuoteView(quote: quote))
                case let table as Markdown.Table:
                    TableView(table: table)
                default:
                    MarkdownView(node.markup)
                }
            }
        }
        .padding(.leading, 10)
        .overlay(Rectangle()
            .frame(width: 3, height: nil, alignment: .leading)
            .foregroundColor(Color.secondary.opacity(0.5)),
                 alignment: .leading)
        .foregroundColor(.secondary)
    }
}

fileprivate struct ParagraphView: View {
    @Environment(\.customParagraph) private var customParagraph
    
    enum ParagraphElement {
        case paragraph(content: AttributedString)
        case mathParagraph(content: String)
        case image(url: URL)
    }
    
    let elements: Array<ParagraphElement>
    
    init(_ paragraph: Paragraph) {
        func createParagraph(_ substring: AttributedSubstring) -> ParagraphElement {
            let characters = String(substring.characters)
            if characters.contains(/\$(.+)\$/) {
                return .mathParagraph(content: characters)
            } else {
                return .paragraph(content: AttributedString(substring))
            }
        }
        
        let content = paragraph.detachedFromParent.format()
        var elements: [ParagraphElement] = []
        
        if let attributedContent = try? AttributedString(markdown: content, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            var leadingBorder = attributedContent.startIndex
            for run in attributedContent.runs {
                if let url = run.imageURL {
                    let leadingSegment = attributedContent[leadingBorder..<run.range.lowerBound]
                    elements.append(createParagraph(leadingSegment))
                    elements.append(.image(url: url))
                    leadingBorder = run.range.upperBound
                }
            }
            if leadingBorder != attributedContent.endIndex {
                let trailingSegment = attributedContent[leadingBorder..<attributedContent.endIndex]
                elements.append(createParagraph(trailingSegment))
            }
        } else {
            elements.append(.paragraph(content: AttributedString(content)))
        }
        
        self.elements = elements
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(elements.enumerated()), id: \.offset) { index, element in
                switch(element) {
                case .paragraph(let text):
                    if let customParagraph = customParagraph {
                        customParagraph(text)
                    } else {
                        SwiftUI.Text(text)
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                case .mathParagraph(let content):
                    LaTeX(content)
                        .errorMode(.rendered)
                        .font(.callout)
                case .image(let url):
                    HStack {
                        Spacer()
                        CachedAsyncImage(url: url) { phase in
                            if let image = phase.image {
                                ImageWithPopover(image: image)
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

fileprivate struct TableView: View {
    let table: Markdown.Table
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Grid {
                Divider()
                    .frame(minHeight: 2)
                    .background(Color.secondary.opacity(0.5))
                GridRow {
                    TableRowView(row: table.head)
                        .fontWeight(.bold)
                }
                Divider()
                    .background(Color.secondary.opacity(0.5))
                ForEach(table.body.items()) { rowItem in
                    TableRowView(row: rowItem.markup as! any TableCellContainer)
                }
                Divider()
                    .frame(minHeight: 2)
                    .background(Color.secondary.opacity(0.5))
            }
        }
    }
}

fileprivate struct TableRowView: View {
    let row: any TableCellContainer
    
    var body: some View {
        GridRow {
            ForEach(row.items()) { item in
                SwiftUI.Text((item.markup as! Markdown.Table.Cell).plainText)
            }
        }
    }
}

// MARK: Custom Paragraph

fileprivate struct CustomParagraphKey: EnvironmentKey {
    static let defaultValue: ((AttributedString) -> AnyView)? = nil
}

extension EnvironmentValues {
    var customParagraph: ((AttributedString) -> AnyView)? {
        get { self[CustomParagraphKey.self] }
        set { self[CustomParagraphKey.self] = newValue }
    }
}

// MARK: Extension

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

extension TableCellContainer {
    fileprivate func items() -> [MarkupNode] {
        return self.cells.map { cell in
            MarkupNode(cell)
        }
    }
}

extension Markdown.Table.Body {
    fileprivate func items() -> [MarkupNode] {
        return self.rows.map { row in
            MarkupNode(row)
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

// MARK: Preview

struct MarkdownView_Previews: PreviewProvider {
    static let previewContent = """
    # Title 1
    ## Title 2
    ### Title 3
    #### Title 4
    ##### Title 5
    
    This is a paragraph. This is **bold** and _underline_, This is `inline_code`.
    This is another sentence $a^2+b^2=c^2$
    
    > Tip: This is a `tip` aside.
    > It may have a presentation similar to a block quote, but with a
    > different meaning.
    
    
    | Section A | Section B | Section C |
    | ---- | ---- | ---- |
    | Yes | A     |A    |
    | No  | A    | C |
    | No | B | A    |
    
    ---------
    
    > This is a quote.
    > Second quote.
    > > Quote stack.
    > > Another quote.
    > - item
    > # Title inside quote.
    
    1. Item 1
    2. Item 2
    3. Item 3
    
    -------
    
    2. Item 2
    3. Item 3
    4. Item 4
    
    - [x] Checked
      - [ ] Not checked
    
    ```
    #include <stdio.h>
    int main() {
        print("Hello world!);
    
        return 0;
    }
    ```
    """
    
    static var previews: some View {
        ScrollView {
            MarkdownView(previewContent)
                .padding()
        }
    }
}
