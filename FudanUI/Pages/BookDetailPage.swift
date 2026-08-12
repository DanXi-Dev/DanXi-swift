import FudanKit
import SwiftUI
import ViewUtils

struct BookDetailPage: View {
    private let book: Book
    private let previewBook: Book?
    private let previewHoldings: [BookHolding]?

    init(_ book: Book) {
        self.book = book
        previewBook = nil
        previewHoldings = nil
    }

    init(previewBook: Book, previewHoldings: [BookHolding]) {
        book = previewBook
        self.previewBook = previewBook
        self.previewHoldings = previewHoldings
    }

    var body: some View {
        AsyncContentView {
            if let previewBook {
                return previewBook
            }
            return try await BookAPI.getBook(id: book.id)
        } content: { book in
            BookDetailContent(book: book, previewHoldings: previewHoldings)
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct BookDetailContent: View {
    private let pageSize = 20

    let book: Book
    let previewHoldings: [BookHolding]?

    var body: some View {
        List {
            Section {
                Text(book.title)
                    .font(.title3)
                    .fontWeight(.semibold)

                if !book.authors.isEmpty {
                    LabeledContent(String(localized: "Author", bundle: .module)) {
                        Text(book.authors.joined(separator: "、"))
                    }
                }

                if let publisher = book.publisher {
                    LabeledContent(String(localized: "Publisher", bundle: .module)) {
                        Text(publisher)
                    }
                }

                if let year = book.year {
                    LabeledContent(String(localized: "Publication Year", bundle: .module)) {
                        Text(String(year))
                    }
                }

                if let isbn = book.isbn {
                    LabeledContent("ISBN") {
                        Text(isbn)
                    }
                }
            }

            if let summary = book.summary {
                Section(String(localized: "Summary", bundle: .module)) {
                    Text(summary)
                }
            }

            Section(String(localized: "Holdings", bundle: .module)) {
                AsyncCollection { (holdings: [BookHolding]) in
                    if let previewHoldings {
                        return holdings.isEmpty ? previewHoldings : []
                    }
                    if !holdings.isEmpty && !holdings.count.isMultiple(of: pageSize) {
                        return []
                    }

                    let page = holdings.count / pageSize + 1
                    return try await BookAPI.getHoldings(
                        bookID: book.id,
                        page: page,
                        pageSize: pageSize
                    )
                } content: { holding in
                    BookHoldingRow(holding: holding)
                }
            }
        }
        #if !os(watchOS)
        .listStyle(.insetGrouped)
        #endif
    }
}

private struct BookHoldingRow: View {
    let holding: BookHolding

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(holding.location)
                    .font(.headline)
                Spacer()
                Text(holding.status)
                    .foregroundStyle(.secondary)
            }

            Text(holding.library)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let callNumber = holding.callNumber {
                Text(callNumber)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            if let volume = holding.volume {
                Text(volume)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }
}

#Preview {
    let books: [Book] = decodePreviewData(filename: "books", directory: "library")
    let holdings: [BookHolding] = decodePreviewData(filename: "holdings", directory: "library")

    BookDetailPage(previewBook: books[0], previewHoldings: holdings)
        .previewPrepared()
}
