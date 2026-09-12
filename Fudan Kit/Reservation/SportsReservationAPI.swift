import Foundation

/// JSON API used by the current “体育场馆网上预约” platform (topic 48).
public enum SportsReservationAPI {
    public static let topicID = 48

    private static let baseURL = URL(string: "https://booking.fudan.edu.cn")!
    private static let homePageURL = URL(
        string: "https://booking.fudan.edu.cn/reservation/fe/site/home"
    )!
    private static let sportsPageURL = URL(
        string: "https://booking.fudan.edu.cn/reservation/fe/site/special/special?id=48"
    )!
    private static let loginURL: URL = {
        var components = URLComponents(
            string: "https://booking.fudan.edu.cn/reservation/api/login/main"
        )!
        components.queryItems = [
            URLQueryItem(name: "redirect_url", value: homePageURL.absoluteString)
        ]
        return components.url!
    }()

    // MARK: - Read APIs

    public static func getTopic() async throws -> BookingTopic {
        let endpoint = "/reservation/api/topic/detail"
        let request = try makeRequest(
            endpoint: endpoint,
            queryItems: [URLQueryItem(name: "id", value: String(topicID))],
            signed: true,
            referer: sportsPageURL
        )
        return try await send(request)
    }

    public static func webReservationURL(venueID: Int) -> URL {
        reservationPageURL(venueID: venueID)
    }

    public static func getVenues(page: Int = 1, pageSize: Int = 10) async throws -> BookingVenuePage {
        let endpoint = "/reservation/api/topic/resource-list"
        let request = try makeRequest(
            endpoint: endpoint,
            queryItems: [
                URLQueryItem(name: "p", value: String(page)),
                URLQueryItem(name: "attr", value: "{}"),
                URLQueryItem(name: "pageSize", value: String(pageSize)),
                URLQueryItem(name: "id", value: String(topicID)),
                URLQueryItem(name: "hideTime", value: "1"),
                URLQueryItem(name: "date", value: "")
            ],
            signed: true,
            referer: sportsPageURL
        )
        return try await send(request)
    }

    public static func getVenueDetail(id: Int) async throws -> BookingVenueDetail {
        let endpoint = "/reservation/site/resource/detail"
        let request = try makeRequest(
            endpoint: endpoint,
            queryItems: [URLQueryItem(name: "id", value: String(id))],
            signed: true,
            referer: reservationPageURL(venueID: id)
        )
        return try await send(request)
    }

    public static func getContact() async throws -> BookingContact {
        let endpoint = "/reservation/site/user/detail-mobile"
        let request = try makeRequest(
            endpoint: endpoint,
            signed: true,
            referer: sportsPageURL
        )
        return try await send(request)
    }

    public static func getCalendar(venueID: Int, from startDate: Date, through endDate: Date) async throws -> BookingCalendar {
        let endpoint = "/reservation/site/resource/calendar"
        let range = BookingDateRange(
            startDate: dateString(startDate),
            endDate: dateString(endDate)
        )
        let encodedRange = try encodeJSONString(range)
        let request = try makeRequest(
            endpoint: endpoint,
            queryItems: [
                URLQueryItem(name: "resource_id", value: String(venueID)),
                URLQueryItem(name: "id", value: String(venueID)),
                URLQueryItem(name: "collective", value: "0"),
                URLQueryItem(name: "date", value: encodedRange)
            ],
            // The captured calendar requests are the only JSON requests without sign-key.
            signed: false,
            referer: reservationPageURL(venueID: venueID)
        )
        return try await send(request)
    }

    public static func getReservationInfo(
        venueID: Int,
        resourceIDs: [Int],
        date: Date,
        period: BookingPeriod,
        page: Int = 1,
        pageSize: Int = 15
    ) async throws -> BookingReservationInfoPage {
        let endpoint = "/reservation/site/resource/reserve-info"
        var queryItems = resourceIDs.map {
            URLQueryItem(name: "id[]", value: String($0))
        }
        queryItems += [
            URLQueryItem(name: "date", value: dateString(date)),
            URLQueryItem(name: "period_id", value: String(period.id)),
            URLQueryItem(name: "start_time", value: period.startTime),
            URLQueryItem(name: "end_time", value: period.endTime),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pageSize", value: String(pageSize))
        ]
        let request = try makeRequest(
            endpoint: endpoint,
            queryItems: queryItems,
            signed: true,
            referer: reservationPageURL(venueID: venueID)
        )
        return try await send(request)
    }

    public static func getAppointments(page: Int = 1, pageSize: Int = 10) async throws -> BookingAppointmentPage {
        let endpoint = "/reservation/site/appointment/appointment-list"
        let request = try makeRequest(
            endpoint: endpoint,
            queryItems: [
                URLQueryItem(name: "p", value: String(page)),
                URLQueryItem(name: "type", value: "0"),
                URLQueryItem(name: "pageSize", value: String(pageSize))
            ],
            signed: true,
            referer: appointmentsPageURL
        )
        return try await send(request)
    }

    // MARK: - Mutation APIs

    /// Launches a personal sports reservation. The server chooses one available
    /// child resource from `resourceIDs`; pass all child resources from the calendar.
    public static func launch(_ reservation: BookingLaunchRequest) async throws -> BookingLaunchResult {
        guard !reservation.resourceIDs.isEmpty, reservation.number > 0 else {
            throw CampusError.customError(message: "预约场地或数量无效")
        }

        let endpoint = "/reservation/site/resource/launch"
        let launchData = [
            BookingLaunchPayload(
                resourceIDs: reservation.resourceIDs,
                groupID: reservation.groupID,
                period: [
                    BookingLaunchPeriod(
                        date: dateString(reservation.date),
                        periodID: reservation.periodID
                    )
                ],
                number: reservation.number
            )
        ]
        let request = try makeMultipartRequest(
            endpoint: endpoint,
            fields: [
                ("data", try encodeJSONString(launchData)),
                ("data_colle", try encodeJSONString(reservation.collectedFields)),
                ("collective", "0"),
                ("captcha", try encodeJSONString(reservation.captcha))
            ],
            referer: reservationPageURL(venueID: reservation.groupID)
        )
        return try await send(request)
    }

    public static func cancel(appointmentID: Int, detailIDs: [Int]) async throws {
        guard !detailIDs.isEmpty else {
            throw CampusError.customError(message: "没有可取消的预约明细")
        }

        let endpoint = "/reservation/site/appointment/appointment-cancel"
        let request = try makeMultipartRequest(
            endpoint: endpoint,
            fields: [
                ("appointment_id", String(appointmentID)),
                ("appointment_detail_id", try encodeJSONString(detailIDs))
            ],
            referer: appointmentsPageURL
        )
        let _: [BookingEmptyResponse] = try await send(request)
    }

    // MARK: - Request construction

    private static let appointmentsPageURL = URL(
        string: "https://booking.fudan.edu.cn/reservation/fe/site/m_myReservation"
    )!

    private static func reservationPageURL(venueID: Int?) -> URL {
        var components = URLComponents(
            string: "https://booking.fudan.edu.cn/reservation/fe/site/m_launchReservation"
        )!
        if let venueID {
            components.queryItems = [URLQueryItem(name: "id", value: String(venueID))]
        }
        return components.url!
    }

    private static func makeRequest(
        endpoint: String,
        queryItems: [URLQueryItem] = [],
        signed: Bool,
        referer: URL
    ) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw LocatableError()
        }
        components.path = endpoint
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else {
            throw LocatableError()
        }

        var request = constructRequest(url)
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.setValue(referer.absoluteString, forHTTPHeaderField: "Referer")
        if signed {
            request.setValue(signKey(endpoint: endpoint, method: "GET"), forHTTPHeaderField: "sign-key")
        }
        return request
    }

    private static func makeMultipartRequest(
        endpoint: String,
        fields: [(name: String, value: String)],
        referer: URL
    ) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw LocatableError()
        }
        components.path = endpoint
        guard let url = components.url else {
            throw LocatableError()
        }
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = constructRequest(url, method: "POST")
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("https://booking.fudan.edu.cn", forHTTPHeaderField: "Origin")
        request.setValue(referer.absoluteString, forHTTPHeaderField: "Referer")
        request.setValue(signKey(endpoint: endpoint, method: "POST"), forHTTPHeaderField: "sign-key")
        request.httpBody = multipartBody(fields: fields, boundary: boundary)
        return request
    }

    private static func signKey(endpoint: String, method: String) -> String {
        endpoint + method.lowercased()
    }

    private static func multipartBody(fields: [(name: String, value: String)], boundary: String) -> Data {
        var body = Data()
        for field in fields {
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(Data("Content-Disposition: form-data; name=\"\(field.name)\"\r\n\r\n".utf8))
            body.append(Data(field.value.utf8))
            body.append(Data("\r\n".utf8))
        }
        body.append(Data("--\(boundary)--\r\n".utf8))
        return body
    }

    private static func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        var (data, response) = try await Authenticator.neo.authenticateRequest(
            request: request,
            loginURL: loginURL
        )
        try validateHTTPResponse(response)

        var envelope: BookingResponseEnvelope<Response> = try decodeEnvelope(data)
        if envelope.code.requiresAuthentication {
            (data, response) = try await Authenticator.neo.authenticateRequest(
                request: request,
                loginURL: loginURL,
                forceRelogin: true
            )
            try validateHTTPResponse(response)
            envelope = try decodeEnvelope(data)
        }

        guard envelope.code.isSuccess, let value = envelope.data else {
            throw CampusError.customError(message: envelope.message.isEmpty ? "预约服务请求失败" : envelope.message)
        }
        return value
    }

    private static func decodeEnvelope<Response: Decodable>(_ data: Data) throws -> BookingResponseEnvelope<Response> {
        do {
            return try JSONDecoder().decode(BookingResponseEnvelope<Response>.self, from: data)
        } catch {
            throw CampusError.customError(message: "预约服务返回了无法解析的数据：\(error.localizedDescription)")
        }
    }

    private static func validateHTTPResponse(_ response: URLResponse) throws {
        if let response = response as? HTTPURLResponse,
           !(200 ... 299).contains(response.statusCode) {
            throw CampusError.customError(message: "预约服务请求失败（HTTP \(response.statusCode)）")
        }
    }

    private static func encodeJSONString<Value: Encodable>(_ value: Value) throws -> String {
        let data = try JSONEncoder().encode(value)
        guard let string = String(data: data, encoding: .utf8) else {
            throw LocatableError()
        }
        return string
    }

    /// Dates in this service are campus-local dates, not UTC dates.
    private static func dateString(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }
}

private struct BookingDateRange: Encodable {
    let startDate: String
    let endDate: String

    private enum CodingKeys: String, CodingKey {
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

private struct BookingLaunchPayload: Encodable {
    let resourceIDs: [Int]
    let groupID: Int
    let period: [BookingLaunchPeriod]
    let number: Int

    private enum CodingKeys: String, CodingKey {
        case resourceIDs = "resource_ids"
        case groupID = "group_id"
        case period, number
    }
}

private struct BookingLaunchPeriod: Encodable {
    let date: String
    let periodID: Int

    private enum CodingKeys: String, CodingKey {
        case date
        case periodID = "period_id"
    }
}

private struct BookingResponseEnvelope<Value: Decodable>: Decodable {
    let code: BookingResponseCode
    let message: String
    let data: Value?

    private enum CodingKeys: String, CodingKey {
        case code = "e"
        case message = "m"
        case data = "d"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(BookingResponseCode.self, forKey: .code)
        message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
        data = code.isSuccess ? try container.decode(Value.self, forKey: .data) : nil
    }
}

private struct BookingResponseCode: Decodable {
    let rawValue: String

    var isSuccess: Bool {
        rawValue == "OK" || rawValue == "0"
    }

    var requiresAuthentication: Bool {
        rawValue == "UN_AUTH"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            rawValue = string
        } else {
            rawValue = String(try container.decode(Int.self))
        }
    }
}

private struct BookingEmptyResponse: Decodable {}
