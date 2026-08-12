import FudanKit
import SwiftUI
import ViewUtils

struct BookSearchPage: View {
    private let pageSize = 20
    private let previewBooks: [Book]?

    @State private var searchText: String
    @State private var query: String

    init() {
        previewBooks = nil
        _searchText = State(initialValue: "")
        _query = State(initialValue: "")
    }

    init(previewBooks: [Book]) {
        self.previewBooks = previewBooks
        _searchText = State(initialValue: "水乳大地")
        _query = State(initialValue: "水乳大地")
    }

    var body: some View {
        List {
            if query.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "books.vertical")
                        .font(.largeTitle)
                    Text("Enter a book title to search", bundle: .module)
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                AsyncCollection { (books: [Book]) in
                    if let previewBooks {
                        return books.isEmpty ? previewBooks : []
                    }
                    if !books.isEmpty && !books.count.isMultiple(of: pageSize) {
                        return []
                    }

                    let page = books.count / pageSize + 1
                    return try await BookAPI.searchBooks(
                        title: query,
                        page: page,
                        pageSize: pageSize
                    )
                } content: { book in
                    DetailLink(value: book) {
                        BookRow(book: book)
                            .navigationStyle()
                    }
                }
                .id(query)
            }
        }
        #if !os(watchOS)
        .listStyle(.inset)
        #endif
        #if os(watchOS)
        .searchable(
            text: $searchText,
            prompt: Text("Search by book title", bundle: .module)
        )
        #else
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text("Search by book title", bundle: .module)
        )
        #endif
        .onSubmit(of: .search) {
            query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .navigationTitle(String(localized: "Library Books", bundle: .module))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct BookRow: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(book.title)
                .font(.headline)

            if !book.authors.isEmpty {
                Text(book.authors.joined(separator: "、"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            let publication = [book.publisher, book.year.map { String($0) }]
                .compactMap { $0 }
                .joined(separator: " · ")
            if !publication.isEmpty {
                Text(publication)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }
}

#Preview {
    let books: [Book] = decodePreviewData(filename: "books", directory: "library")

    BookSearchPage(previewBooks: books)
        .previewPrepared()
}
