import FudanKit
import SwiftUI
import TipKit
import Utils
import ViewUtils

struct BookSearchPage: View {
    private let pageSize = 20
    private let previewBooks: [Book]?
    private let previewPinnedBooks: [Book]?

    @AppStorage("library-pinned-books") private var storedPinnedBooks: [Book] = []
    @State private var searchText: String
    @State private var query: String
    #if !os(watchOS)
    @available(iOS 17.0, *)
    private var pinnedBooksTip: PinnedBooksTip { .init() }
    #endif

    private var pinnedBooks: [Book] {
        previewPinnedBooks ?? storedPinnedBooks
    }

    init() {
        previewBooks = nil
        previewPinnedBooks = nil
        _searchText = State(initialValue: "")
        _query = State(initialValue: "")
    }

    init(previewBooks: [Book]) {
        self.previewBooks = previewBooks
        previewPinnedBooks = nil
        _searchText = State(initialValue: "水乳大地")
        _query = State(initialValue: "水乳大地")
    }

    init(previewPinnedBooks: [Book]) {
        previewBooks = nil
        self.previewPinnedBooks = previewPinnedBooks
        _searchText = State(initialValue: "")
        _query = State(initialValue: "")
    }

    var body: some View {
        List {
            if query.isEmpty {
                if pinnedBooks.isEmpty {
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
                    Section(String(localized: "Pinned Books", bundle: .module)) {
                        #if !os(watchOS)
                        if #available(iOS 17.0, *) {
                            TipView(pinnedBooksTip)
                        }
                        #endif

                        ForEach(pinnedBooks) { book in
                            DetailLink(value: book, action: {
                                #if !os(watchOS)
                                if #available(iOS 17.0, *) {
                                    pinnedBooksTip.invalidate(reason: .actionPerformed)
                                }
                                #endif
                            }) {
                                BookRow(book: book)
                                    .navigationStyle()
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        storedPinnedBooks.removeAll { $0.id == book.id }
                                    }
                                } label: {
                                    Label(String(localized: "Remove", bundle: .module), systemImage: "trash")
                                }
                            }
                        }
                    }
                }
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
        .onChange(of: searchText) { searchText in
            if searchText.isEmpty {
                query = ""
            }
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
        .environmentObject(AppNavigator())
}

#Preview("Pinned Books") {
    let books: [Book] = decodePreviewData(filename: "books", directory: "library")

    BookSearchPage(previewPinnedBooks: books)
        .previewPrepared()
        .environmentObject(AppNavigator())
}
