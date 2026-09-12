import Foundation
import SwiftSoup

public struct BookingRichText: Decodable, Hashable, Sendable {
    public let html: String
    public let label: String
    public let isEnabled: Bool

    private enum CodingKeys: String, CodingKey {
        case html = "text"
        case label
        // This misspelling is part of the upstream API.
        case enabled = "enanle"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        html = try container.decodeIfPresent(String.self, forKey: .html) ?? ""
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        isEnabled = try container.decodeIfPresent(BookingFlexibleBool.self, forKey: .enabled)?.value ?? true
    }

    public var plainText: String {
        guard let body = try? SwiftSoup.parse(html).body() else { return html }
        let blocks = body.children().compactMap { try? $0.text() }.filter { !$0.isEmpty }
        return blocks.isEmpty ? ((try? body.text()) ?? html) : blocks.joined(separator: "\n\n")
    }
}

public struct BookingTopic: Decodable, Sendable {
    public let name: String
    public let visitCount: Int
    public let appointmentCount: Int
    public let description: BookingRichText

    private enum CodingKeys: String, CodingKey {
        case name, description = "desc"
        case visitCount = "visit_num"
        case appointmentCount = "appointment_num"
    }
}

/// A page of resources exposed by the new booking platform.
public struct BookingVenuePage: Decodable, Sendable {
    public let venues: [BookingVenue]
    public let page: Int
    public let pageSize: Int
    public let total: Int

    private enum CodingKeys: String, CodingKey {
        case data, page, perpage, total
    }

    private struct Entry: Decodable {
        let base: BookingVenue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        venues = try container.decode([Entry].self, forKey: .data).map(\.base)
        page = try container.decode(BookingFlexibleInt.self, forKey: .page).value
        pageSize = try container.decode(BookingFlexibleInt.self, forKey: .perpage).value
        total = try container.decode(Int.self, forKey: .total)
    }
}

/// A top-level venue/group, such as “北区体育馆-乒乓球”.
public struct BookingVenue: Identifiable, Decodable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let icon: String
    public let images: String
    public let type: Int
    public let requiredFields: [BookingFormField]
    public let introduction: BookingRichText?

    private enum CodingKeys: String, CodingKey {
        case id, name, icon, images, type, config
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? ""
        images = try container.decodeIfPresent(String.self, forKey: .images) ?? ""
        type = try container.decode(Int.self, forKey: .type)
        let configuration = try container.decodeIfPresent(BookingResourceConfiguration.self, forKey: .config)
        requiredFields = configuration?.requiredFields ?? []
        introduction = configuration?.introduction
    }

    public var imageURL: URL? {
        guard !images.isEmpty else { return nil }
        var components = URLComponents(
            string: "https://booking.fudan.edu.cn/reservation/api/file/down"
        )
        components?.queryItems = [
            URLQueryItem(name: "token", value: images),
            URLQueryItem(name: "view", value: "1")
        ]
        return components?.url
    }
}

/// Detailed booking rules needed before showing or launching a reservation.
public struct BookingVenueDetail: Identifiable, Decodable, Sendable {
    public let id: Int
    public let name: String
    public let type: Int
    public let exclusive: Bool
    public let isGroup: Bool
    public let usable: Bool
    public let limitInfo: String
    public let requiredFields: [BookingFormField]
    public let serviceTimes: [BookingServiceTime]
    public let introduction: BookingRichText?
    public let bookingDescription: BookingRichText?
    public let requiresCaptcha: Bool

    private enum CodingKeys: String, CodingKey {
        case id, name, type, exclusive, usable, config, rule
        case isGroup = "is_group"
        case limitInfo = "limit_info"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(Int.self, forKey: .type)
        exclusive = try container.decode(BookingFlexibleBool.self, forKey: .exclusive).value
        isGroup = try container.decode(BookingFlexibleBool.self, forKey: .isGroup).value
        usable = try container.decode(Bool.self, forKey: .usable)
        limitInfo = try container.decodeIfPresent(String.self, forKey: .limitInfo) ?? ""
        let configuration = try container.decodeIfPresent(BookingResourceConfiguration.self, forKey: .config)
        requiredFields = configuration?.requiredFields ?? []
        introduction = configuration?.introduction
        bookingDescription = configuration?.description
        requiresCaptcha = configuration?.antiBot != 0
        serviceTimes = try container.decodeIfPresent([BookingServiceTime].self, forKey: .rule) ?? []
    }
}

public struct BookingServiceTime: Decodable, Hashable, Sendable {
    public let startTime: String
    public let endTime: String

    private enum CodingKeys: String, CodingKey {
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

public struct BookingFormField: Decodable, Hashable, Sendable {
    public let name: String
    public let type: String
    public let verificationType: String?

    private enum CodingKeys: String, CodingKey {
        case name, type
        case verificationType = "verifyType"
    }

    public var isRequired: Bool {
        verificationType == "required"
    }
}

private struct BookingResourceConfiguration: Decodable {
    let requiredFields: [BookingFormField]
    let introduction: BookingRichText?
    let description: BookingRichText?
    let antiBot: Int

    private enum CodingKeys: String, CodingKey {
        case requiredFields = "data_colle"
        case introduction, description
        case antiBot = "anti_bot"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        requiredFields = try container.decodeIfPresent([BookingFormField].self, forKey: .requiredFields) ?? []
        introduction = try container.decodeIfPresent(BookingRichText.self, forKey: .introduction)
        description = try container.decodeIfPresent(BookingRichText.self, forKey: .description)
        antiBot = try container.decodeIfPresent(BookingFlexibleInt.self, forKey: .antiBot)?.value ?? 0
    }
}

public struct BookingContact: Decodable, Sendable {
    public let mobile: String
    public let idCard: String

    private enum CodingKeys: String, CodingKey {
        case mobile
        case idCard = "id_card"
    }
}

/// One reservable child resource, such as “1号场地”.
public struct BookingCourt: Identifiable, Decodable, Hashable, Sendable {
    public let id: Int
    public let name: String
}

public struct BookingPeriod: Identifiable, Decodable, Hashable, Sendable {
    public let id: Int
    public let displayTime: String
    public let startTime: String
    public let endTime: String

    private enum CodingKeys: String, CodingKey {
        case id
        case displayTime = "str_time"
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

public struct BookingAvailability: Decodable, Hashable, Sendable {
    public let status: Int
    public let total: Int
    public let remaining: Int

    private enum CodingKeys: String, CodingKey {
        case status, total
        case remaining = "num"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(Int.self, forKey: .status)
        total = try container.decode(Int.self, forKey: .total)
        remaining = try container.decode(BookingFlexibleInt.self, forKey: .remaining).value
    }

    /// Observed in the HAR: status 0 is open; 2 and 3 are not selectable.
    public var isAvailable: Bool {
        status == 0 && remaining > 0
    }
}

/// Availability is keyed by date string, then child resource ID, then period ID.
public struct BookingCalendar: Decodable, Sendable {
    public let days: [String]
    public let periods: [BookingPeriod]
    public let courts: [BookingCourt]
    public let availability: [String: [String: [String: BookingAvailability]]]

    private enum CodingKeys: String, CodingKey {
        case days = "day"
        case periods = "time"
        case courts = "resource"
        case availability = "data"
    }

    public func availability(on date: String, courtID: Int, periodID: Int) -> BookingAvailability? {
        availability[date]?[String(courtID)]?[String(periodID)]
    }

    public func availableCourts(on date: String, periodID: Int) -> [BookingCourt] {
        courts.filter { court in
            availability(on: date, courtID: court.id, periodID: periodID)?.isAvailable == true
        }
    }
}

public struct BookingReservationInfoPage: Decodable, Sendable {
    public let reservations: [BookingReservationInfo]
    public let page: Int
    public let pageSize: Int
    public let total: Int

    private enum CodingKeys: String, CodingKey {
        case data, page, perpage, total
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reservations = try container.decode([BookingReservationInfo].self, forKey: .data)
        page = try container.decode(BookingFlexibleInt.self, forKey: .page).value
        pageSize = try container.decode(BookingFlexibleInt.self, forKey: .perpage).value
        total = try container.decode(Int.self, forKey: .total)
    }
}

/// Public information returned when inspecting who occupies a time slot.
public struct BookingReservationInfo: Identifiable, Decodable, Sendable {
    public let id: Int
    public let name: String
    public let number: String?
    public let mobile: String?
    public let departmentName: String?
    public let collective: Bool
    public let showSystem: Bool

    private enum CodingKeys: String, CodingKey {
        case id, name, number, mobile, collective
        case departmentName = "department_name"
        case showSystem = "show_system"
    }
}

public struct BookingCollectedField: Encodable, Hashable, Sendable {
    public let name: String
    public let value: String
    public let verification: String?
    public let type: String

    private enum CodingKeys: String, CodingKey {
        case name, value, type
        case verification = "verify"
    }

    public init(name: String, value: String, verification: String? = nil, type: String) {
        self.name = name
        self.value = value
        self.verification = verification
        self.type = type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(value, forKey: .value)
        if let verification {
            try container.encode(verification, forKey: .verification)
        } else {
            try container.encodeNil(forKey: .verification)
        }
        try container.encode(type, forKey: .type)
    }
}

public struct BookingCaptcha: Encodable, Hashable, Sendable {
    public let token: String
    public let pointJSON: String

    private enum CodingKeys: String, CodingKey {
        case token
        case pointJSON = "pointJson"
    }

    public init(token: String = "", pointJSON: String = "") {
        self.token = token
        self.pointJSON = pointJSON
    }
}

public struct BookingLaunchRequest: Sendable {
    public let groupID: Int
    public let resourceIDs: [Int]
    public let date: Date
    public let periodID: Int
    public let number: Int
    public let collectedFields: [BookingCollectedField]
    public let captcha: BookingCaptcha

    public init(
        groupID: Int,
        resourceIDs: [Int],
        date: Date,
        periodID: Int,
        number: Int = 1,
        collectedFields: [BookingCollectedField],
        captcha: BookingCaptcha = BookingCaptcha()
    ) {
        self.groupID = groupID
        self.resourceIDs = resourceIDs
        self.date = date
        self.periodID = periodID
        self.number = number
        self.collectedFields = collectedFields
        self.captcha = captcha
    }
}

public struct BookingLaunchResult: Decodable, Sendable {
    public let isRelatedApproval: Bool
    public let processID: Int
    public let processURL: String

    private enum CodingKeys: String, CodingKey {
        case isRelatedApproval = "is_relate"
        case processID = "process_id"
        case processURL = "process_url"
    }
}

public struct BookingAppointmentPage: Decodable, Sendable {
    public let appointments: [BookingAppointment]
    public let page: Int
    public let pageSize: Int
    public let total: Int

    private enum CodingKeys: String, CodingKey {
        case data, page, perpage, total
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appointments = try container.decode([BookingAppointment].self, forKey: .data)
        page = try container.decode(BookingFlexibleInt.self, forKey: .page).value
        pageSize = try container.decode(BookingFlexibleInt.self, forKey: .perpage).value
        total = try container.decode(Int.self, forKey: .total)
    }
}

public struct BookingAppointment: Identifiable, Decodable, Sendable {
    public let id: Int
    public let resourceID: Int
    public let groupID: Int
    public let resourceName: String
    public let status: Int
    public let statusName: String
    public let createdAt: String
    public let detailByDate: [String: [BookingAppointmentDetail]]
    public let canCancel: Bool

    private enum CodingKeys: String, CodingKey {
        case id, status, created, detail
        case resourceID = "resource_id"
        case groupID = "group_id"
        case resourceName = "resource_name"
        case statusName = "status_name"
        case canCancel = "is_cancel"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        resourceID = try container.decode(Int.self, forKey: .resourceID)
        groupID = try container.decode(Int.self, forKey: .groupID)
        resourceName = try container.decode(String.self, forKey: .resourceName)
        status = try container.decode(Int.self, forKey: .status)
        statusName = try container.decode(String.self, forKey: .statusName)
        createdAt = try container.decode(String.self, forKey: .created)
        detailByDate = try container.decode([String: [BookingAppointmentDetail]].self, forKey: .detail)
        canCancel = try container.decode(BookingFlexibleBool.self, forKey: .canCancel).value
    }

    public var details: [BookingAppointmentDetail] {
        detailByDate.keys.sorted().flatMap { detailByDate[$0] ?? [] }
    }
}

public struct BookingAppointmentDetail: Identifiable, Decodable, Sendable {
    public let id: Int
    public let appointmentID: Int
    public let date: String
    public let periodID: Int
    public let startTime: String
    public let endTime: String
    public let displayTime: String
    public let canCancel: Bool

    private enum CodingKeys: String, CodingKey {
        case id, date
        case appointmentID = "appointment_id"
        case periodID = "period_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case displayTime = "str_time"
        case canCancel = "is_cancel"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        appointmentID = try container.decode(Int.self, forKey: .appointmentID)
        date = try container.decode(String.self, forKey: .date)
        periodID = try container.decode(Int.self, forKey: .periodID)
        startTime = try container.decode(String.self, forKey: .startTime)
        endTime = try container.decode(String.self, forKey: .endTime)
        displayTime = try container.decode(String.self, forKey: .displayTime)
        canCancel = try container.decode(BookingFlexibleBool.self, forKey: .canCancel).value
    }
}

struct BookingFlexibleInt: Decodable {
    let value: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let integer = try? container.decode(Int.self) {
            value = integer
        } else {
            let string = try container.decode(String.self)
            guard let integer = Int(string) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected an integer or numeric string")
            }
            value = integer
        }
    }
}

struct BookingFlexibleBool: Decodable {
    let value: Bool

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolean = try? container.decode(Bool.self) {
            value = boolean
        } else if let integer = try? container.decode(Int.self) {
            value = integer != 0
        } else {
            let string = try container.decode(String.self)
            switch string.lowercased() {
            case "1", "true": value = true
            case "0", "false": value = false
            default:
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected a Boolean-compatible value")
            }
        }
    }
}
