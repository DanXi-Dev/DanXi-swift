import Foundation

/// A page returned by the library's reader services.
public struct LibraryAccountPage<Item: Decodable & Sendable>: Decodable, Sendable {
    public let items: [Item]
    public let total: Int
    public let page: Int?
    public let pageSize: Int?

    private enum CodingKeys: String, CodingKey {
        case items = "list"
        case total, pageSize
        case page = "pageNo"
    }
}

public struct LibraryReaderInfo: Decodable, Sendable {
    public let barcode: String
    public let name: String
    public let canLoanTotal: Int?
    public let currentRequestCount: Int?
}

public struct LibraryCurrentLoan: Identifiable, Decodable, Sendable {
    public let id: String
    public let itemBarcode: String
    public let title: String
    public let author: String?
    public let library: String?
    public let location: String?
    public let loanDate: String
    public let dueDate: String
    public let renewalCount: Int
    public let renewalLimit: Int?

    private enum CodingKeys: String, CodingKey {
        case loanLog, itemInfo, circulationLoanPolicy
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let log = try container.decode(LoanLog.self, forKey: .loanLog)
        let info = try container.decodeIfPresent(ItemInfo.self, forKey: .itemInfo)
        let policy = try container.decodeIfPresent(LoanPolicy.self, forKey: .circulationLoanPolicy)
        guard let barcode = info?.item?.barcode ?? log.itemBarcode else {
            throw DecodingError.dataCorruptedError(
                forKey: .itemInfo,
                in: container,
                debugDescription: "当前借阅缺少册条码"
            )
        }
        id = barcode
        itemBarcode = barcode
        title = info?.instance?.title ?? barcode
        author = info?.instance?.author
        library = info?.item?.temporaryLibraryName
        location = info?.item?.temporaryLocationName
        loanDate = log.loanDate
        dueDate = log.dueDate
        renewalCount = log.renewalCount
        renewalLimit = policy?.renewalCount
    }
}

public struct LibraryLoanHistoryItem: Identifiable, Decodable, Sendable {
    public let id: String
    public let catalogueID: Int?
    public let itemBarcode: String
    public let title: String
    public let author: String?
    public let loanDate: String
    public let returnDate: String?
    public let dueDate: String?
    public let renewalCount: Int

    private enum CodingKeys: String, CodingKey {
        case catalogueID = "catalogueId"
        case itemBarcode, loanDate, returnDate, dueDate, renewalCount, catalogueInstance
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        catalogueID = try container.decodeIfPresent(Int.self, forKey: .catalogueID)
        itemBarcode = try container.decode(String.self, forKey: .itemBarcode)
        loanDate = try container.decode(String.self, forKey: .loanDate)
        returnDate = try container.decodeIfPresent(String.self, forKey: .returnDate)
        dueDate = try container.decodeIfPresent(String.self, forKey: .dueDate)
        renewalCount = try container.decodeIfPresent(Int.self, forKey: .renewalCount) ?? 0
        let instance = try container.decodeIfPresent(CatalogueInstance.self, forKey: .catalogueInstance)
        title = instance?.title ?? itemBarcode
        author = instance?.author
        id = "\(itemBarcode)-\(loanDate)"
    }
}

public enum LibraryRequestRange: Int, Sendable {
    case current = 0
    case history = 1
}

public struct LibraryBookRequest: Identifiable, Decodable, Sendable {
    public let id: Int
    public let catalogueID: Int?
    public let itemBarcode: String
    public let title: String
    public let author: String?
    public let status: String
    public let statusCode: String?
    public let pickupCode: String
    public let pickupName: String?
    public let expectedDate: String?
    public let createdAt: String?
    public let canReplace: Bool
    public let queuePosition: Int?

    private enum CodingKeys: String, CodingKey {
        case id, itemBarcode, instance, status, statusCode, pickupLocation
        case catalogueID = "catalogueId"
        case pickupName = "pickUpLocationName"
        case expectedDate = "expectDate"
        case createdAt = "createTime"
        case canReplace = "allowReplace"
        case queuePosition = "queuing"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        catalogueID = try container.decodeIfPresent(Int.self, forKey: .catalogueID)
        itemBarcode = try container.decode(String.self, forKey: .itemBarcode)
        let instance = try container.decodeIfPresent(CatalogueInstance.self, forKey: .instance)
        title = instance?.title ?? itemBarcode
        author = instance?.author
        status = try container.decode(String.self, forKey: .status)
        statusCode = try container.decodeIfPresent(String.self, forKey: .statusCode)
        pickupCode = try container.decode(String.self, forKey: .pickupLocation)
        pickupName = try container.decodeIfPresent(String.self, forKey: .pickupName)
        expectedDate = try container.decodeIfPresent(String.self, forKey: .expectedDate)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        canReplace = try container.decodeIfPresent(String.self, forKey: .canReplace) == "1"
        queuePosition = try container.decodeIfPresent(Int.self, forKey: .queuePosition)
    }
}

public struct LibraryRequestPolicy: Decodable, Sendable {
    /// Maximum number of days from today that may be selected as the expected pickup date.
    public let requestDateRange: Int
    public let matchLoanPolicy: Bool
}

public struct LibraryPickupLocation: Identifiable, Decodable, Sendable {
    public let code: String
    public let name: String
    public let address: String?
    public var id: String { code }
}

public struct LibraryPickupLocations: Decodable, Sendable {
    public let loan: [LibraryPickupLocation]
    public let available: [LibraryPickupLocation]
}

public struct LibraryRequestResult: Decodable, Sendable {
    public let id: Int
    public let pickupLocation: String
    public let expectDate: String
    public let status: String
}

private struct LoanLog: Decodable {
    let itemBarcode: String?
    let loanDate: String
    let dueDate: String
    let renewalCount: Int
}

private struct ItemInfo: Decodable {
    let item: Item?
    let instance: CatalogueInstance?
}

private struct Item: Decodable {
    let barcode: String?
    let temporaryLibraryName: String?
    let temporaryLocationName: String?
}

private struct CatalogueInstance: Decodable {
    let title: String?
    let author: String?
}

private struct LoanPolicy: Decodable {
    let renewalCount: Int?
}
