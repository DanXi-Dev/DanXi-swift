import Foundation
import SwiftSoup

/// API collection for searching books and retrieving their holdings.
///
/// The APIs are publicly available and do not require authorization.
public enum BookAPI {
    public static func searchBooks(
        title: String,
        page: Int = 1,
        pageSize: Int = 10
    ) async throws -> [Book] {
        let payload = BookSearchRequest(title: title, page: page, pageSize: pageSize)
        let body = try JSONEncoder().encode(payload)
        var request = constructRequest(
            URL(string: "https://fdulspgw.fudan.edu.cn/urdh/open-api/opac/search/advanced")!,
            payload: body
        )
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, _) = try await URLSession.campusSession.data(for: request)
        let response = try JSONDecoder().decode(BookSearchResponse.self, from: data)
        guard response.success, response.code == 200 else {
            throw CampusError.customError(message: response.message)
        }

        return response.data.books?.map(\.book) ?? []
    }

    public static func getBook(id: String) async throws -> Book {
        let request = constructRequest(
            URL(string: "https://fdulspgw.fudan.edu.cn/urdh/open-api/opac/search/smjlh/\(id)")!
        )
        let (data, _) = try await URLSession.campusSession.data(for: request)
        let response = try JSONDecoder().decode(BookDetailResponse.self, from: data)
        guard response.success, response.code == 200 else {
            throw CampusError.customError(message: response.message)
        }
        guard let book = response.data.first?.book else {
            throw CampusError.customError(message: "未找到图书")
        }
        return book
    }

    public static func getHoldings(
        bookID: String,
        page: Int = 1,
        pageSize: Int = 10
    ) async throws -> [BookHolding] {
        var components = URLComponents(
            string: "https://fdulspgw.fudan.edu.cn/alsp/open-api/opac/v2/holdings"
        )!
        components.queryItems = [
            URLQueryItem(name: "catalogueId", value: bookID),
            URLQueryItem(name: "loanTypeCode", value: ""),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
            URLQueryItem(name: "pageNo", value: String(page)),
            URLQueryItem(name: "display", value: "true")
        ]

        let request = constructRequest(components.url!)
        let (data, _) = try await URLSession.campusSession.data(for: request)
        let response = try JSONDecoder().decode(BookHoldingsResponse.self, from: data)
        guard response.code == 200 else {
            throw CampusError.customError(message: response.message)
        }

        return response.data.holdings?.map(\.holding) ?? []
    }
}

private struct BookSearchRequest: Encodable {
    let resourceType = 1
    let pageSize: Int
    let pageNum: Int
    let searchConditions: [SearchCondition]
    let orderByField = "similarity"
    let orderByType = "desc"
    let aiQuery = false
    let aiMinimumShouldMatch = "70%"
    let publicationYearFrom = ""
    let publicationYearTo = ""

    init(title: String, page: Int, pageSize: Int) {
        self.pageSize = pageSize
        self.pageNum = page
        self.searchConditions = [SearchCondition(title: title)]
    }

    struct SearchCondition: Encodable {
        let field = "resource_ztm"
        let matchType = "contains"
        let value: String
        let `operator` = "AND"
        let noTransaction = false

        init(title: String) {
            self.value = title
        }
    }
}

private struct BookSearchResponse: Decodable {
    let success: Bool
    let code: Int
    let message: String
    let data: Data

    enum CodingKeys: String, CodingKey {
        case success, code, data
        case message = "msg"
    }

    struct Data: Decodable {
        let books: [BookResponse]?

        enum CodingKeys: String, CodingKey {
            case books = "list"
        }
    }
}

private struct BookDetailResponse: Decodable {
    let success: Bool
    let code: Int
    let message: String
    let data: [BookResponse]

    enum CodingKeys: String, CodingKey {
        case success, code, data
        case message = "msg"
    }
}

private struct BookResponse: Decodable {
    let id: String
    let title: String
    let authors: [String]?
    let publisher: String?
    let year: Int?
    let yearText: String?
    let isbns: [String]?
    let summary: String?

    enum CodingKeys: String, CodingKey {
        case id = "docId"
        case title = "resource_ztm"
        case authors = "resource_zrz_arr"
        case publisher = "resource_cbz"
        case year = "publication_year_int"
        case yearText = "resource_cbrq"
        case isbns = "resource_isbn_arr"
        case summary = "resource_zydfz"
    }

    var book: Book {
        Book(
            id: id,
            title: (try? SwiftSoup.parse(title).text()) ?? title,
            authors: authors ?? [],
            publisher: publisher,
            year: year ?? yearText.flatMap(Int.init),
            isbn: preferredISBN,
            summary: summary
        )
    }

    private var preferredISBN: String? {
        let isbns = isbns ?? []
        return isbns.first { isbn in
            isbn.filter { $0.isNumber }.count == 13
        } ?? isbns.first
    }
}

private struct BookHoldingsResponse: Decodable {
    let code: Int
    let message: String
    let data: Data

    enum CodingKeys: String, CodingKey {
        case code, data
        case message = "msg"
    }

    struct Data: Decodable {
        let holdings: [BookHoldingResponse]?

        enum CodingKeys: String, CodingKey {
            case holdings = "list"
        }
    }
}

private struct BookHoldingResponse: Decodable {
    let id: String
    let callNumber: String?
    let library: String
    let location: String
    let status: String
    let volume: String?

    enum CodingKeys: String, CodingKey {
        case id
        case callNumber = "callNo"
        case library = "temporaryLibraryName"
        case location = "temporaryLocationName"
        case status = "itemStatusName"
        case volume = "volumeInfo"
    }

    var holding: BookHolding {
        BookHolding(
            id: id,
            callNumber: callNumber,
            library: library,
            location: location,
            status: status,
            volume: volume
        )
    }
}
