import Foundation

/// A playground that can be reserved
public struct Playground: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let campus: String
    public let category: String
    
    /// This value will be used when constructing an reservation URL
    let categoryId: String
}

/// A reservation time slot, representing a reservable time of a certain playground
public struct Reservation: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let begin, end: Date
    public let reserved, total: Int
    
    let reserveId: String?
    let categoryId: String
    let playgroundId: String
}

extension Reservation {
    public var available: Bool {
        self.reserveId != nil
    }
    
    public var reserveURL: URL? {
        guard let reserveId = reserveId else { return nil }
        var component = URLComponents(string: "https://elife.fudan.edu.cn/public/front/loadOrderForm_ordinary.htm")!
        component.queryItems = [URLQueryItem(name: "serviceContent.id", value: playgroundId),
                                URLQueryItem(name: "serviceCategory.id", value: categoryId),
                                URLQueryItem(name: "resourceIds", value: reserveId),
                                URLQueryItem(name: "codeStr", value: nil),
                                URLQueryItem(name: "orderCounts", value: "1")]
        return component.url!
    }
}
