import Foundation

/// 图书馆目录中的一本书。
public struct Book: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let authors: [String]
    public let publisher: String?
    public let year: Int?
    public let isbn: String?
    public let summary: String?
}

/// 图书馆持有的一本实体书。
public struct BookHolding: Identifiable, Codable, Hashable, Sendable {
    /// 馆藏的唯一标识。
    public let id: String
    /// 用于在书架上定位图书的索书号。
    public let callNumber: String?
    public let library: String
    public let location: String
    public let status: String
    public let volume: String?
    /// Values required by the reader request APIs. Older saved previews may omit them.
    public let barcode: String?
    public let libraryCode: String?
    public let locationCode: String?
    public let canRequest: Bool?
}
