import Foundation

/// State boundary for the rebuilt sports reservation feature.
public actor SportsReservationStore: ClearableStorage {
    public static let shared = SportsReservationStore()

    private var cachedVenues: [BookingVenue]?

    public init() {}

    /// Loads every venue from sports topic 48, following the server's pagination.
    public func getVenues(forceRefresh: Bool = false) async throws -> [BookingVenue] {
        if !forceRefresh, let cachedVenues {
            return cachedVenues
        }

        let pageSize = 10
        var page = 1
        var venues: [BookingVenue] = []
        var total = Int.max

        while venues.count < total {
            let response = try await SportsReservationAPI.getVenues(page: page, pageSize: pageSize)
            venues.append(contentsOf: response.venues)
            total = response.total

            guard !response.venues.isEmpty else {
                break
            }
            page += 1
        }

        cachedVenues = venues
        return venues
    }

    public func getVenueDetail(id: Int) async throws -> BookingVenueDetail {
        try await SportsReservationAPI.getVenueDetail(id: id)
    }

    public func getContact() async throws -> BookingContact {
        try await SportsReservationAPI.getContact()
    }

    public func getCalendar(venueID: Int, from startDate: Date, through endDate: Date) async throws -> BookingCalendar {
        try await SportsReservationAPI.getCalendar(venueID: venueID, from: startDate, through: endDate)
    }

    public func getReservationInfo(
        venueID: Int,
        resourceIDs: [Int],
        date: Date,
        period: BookingPeriod,
        page: Int = 1,
        pageSize: Int = 15
    ) async throws -> BookingReservationInfoPage {
        try await SportsReservationAPI.getReservationInfo(
            venueID: venueID,
            resourceIDs: resourceIDs,
            date: date,
            period: period,
            page: page,
            pageSize: pageSize
        )
    }

    public func launch(_ reservation: BookingLaunchRequest) async throws -> BookingLaunchResult {
        try await SportsReservationAPI.launch(reservation)
    }

    public func getAppointments(page: Int = 1, pageSize: Int = 10) async throws -> BookingAppointmentPage {
        try await SportsReservationAPI.getAppointments(page: page, pageSize: pageSize)
    }

    public func cancel(appointmentID: Int, detailIDs: [Int]) async throws {
        try await SportsReservationAPI.cancel(appointmentID: appointmentID, detailIDs: detailIDs)
    }

    public func clearCache() throws {
        cachedVenues = nil
    }
}
