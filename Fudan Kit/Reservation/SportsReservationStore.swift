import Foundation

/// State boundary for the rebuilt sports reservation feature.
public actor SportsReservationStore: ClearableStorage {
    public static let shared = SportsReservationStore()

    private var cachedVenues: [BookingVenue]?
    private var imageIndex: [String: String]?
    private var imageDownloads: [Int: (token: String, task: Task<Data, Error>)] = [:]

    private let imageCacheDirectory: URL = {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SportsReservationImages", isDirectory: true)
    }()

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

        reconcileImageCache(with: venues)
        cachedVenues = venues
        return venues
    }

    public func getVenueImage(_ venue: BookingVenue) async throws -> Data? {
        guard !venue.images.isEmpty else { return nil }

        let key = String(venue.id)
        var index = loadImageIndex()
        let fileURL = imageFileURL(venueID: venue.id)

        if index[key] == venue.images,
           let data = try? Data(contentsOf: fileURL, options: .mappedIfSafe),
           isValidImageData(data) {
            return data
        }

        if index[key] != nil {
            try? FileManager.default.removeItem(at: fileURL)
            index.removeValue(forKey: key)
            saveImageIndex(index)
        }

        let token = venue.images
        let data: Data
        if let download = imageDownloads[venue.id], download.token == token {
            data = try await download.task.value
        } else {
            let task = Task {
                try await SportsReservationAPI.getVenueImage(token: token)
            }
            imageDownloads[venue.id] = (token, task)
            do {
                data = try await task.value
            } catch {
                if imageDownloads[venue.id]?.token == token {
                    imageDownloads.removeValue(forKey: venue.id)
                }
                throw error
            }
        }
        if imageDownloads[venue.id]?.token == token {
            imageDownloads.removeValue(forKey: venue.id)
        }

        // Do not restore an image invalidated by a venue-list refresh while it was downloading.
        if let currentVenue = cachedVenues?.first(where: { $0.id == venue.id }),
           currentVenue.images != token {
            return nil
        }

        try FileManager.default.createDirectory(
            at: imageCacheDirectory,
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
        index = loadImageIndex()
        index[key] = token
        saveImageIndex(index)
        return data
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
        imageIndex = nil
        imageDownloads.values.forEach { $0.task.cancel() }
        imageDownloads.removeAll()
        if FileManager.default.fileExists(atPath: imageCacheDirectory.path) {
            try FileManager.default.removeItem(at: imageCacheDirectory)
        }
    }

    private var imageIndexURL: URL {
        imageCacheDirectory.appendingPathComponent("index.json", isDirectory: false)
    }

    private func imageFileURL(venueID: Int) -> URL {
        imageCacheDirectory.appendingPathComponent("venue-\(venueID).image", isDirectory: false)
    }

    private func loadImageIndex() -> [String: String] {
        if let imageIndex { return imageIndex }
        guard let data = try? Data(contentsOf: imageIndexURL),
              let storedIndex = try? JSONDecoder().decode([String: String].self, from: data) else {
            imageIndex = [:]
            return [:]
        }
        imageIndex = storedIndex
        return storedIndex
    }

    private func saveImageIndex(_ index: [String: String]) {
        do {
            try FileManager.default.createDirectory(
                at: imageCacheDirectory,
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(index)
            try data.write(to: imageIndexURL, options: .atomic)
            imageIndex = index
        } catch {
            // Image caching is best-effort and must not prevent venue loading.
        }
    }

    private func reconcileImageCache(with venues: [BookingVenue]) {
        var index = loadImageIndex()
        let expectedTokens = Dictionary(
            uniqueKeysWithValues: venues
                .filter { !$0.images.isEmpty }
                .map { (String($0.id), $0.images) }
        )

        let invalidEntries = index.compactMap { key, token -> (key: String, fileURL: URL?)? in
            guard let venueID = Int(key) else { return (key: key, fileURL: nil) }
            let fileURL = imageFileURL(venueID: venueID)
            let imageData = try? Data(contentsOf: fileURL, options: .mappedIfSafe)
            guard expectedTokens[key] == token,
                  let imageData,
                  isValidImageData(imageData) else {
                return (key: key, fileURL: fileURL)
            }
            return nil
        }
        for entry in invalidEntries {
            if let fileURL = entry.fileURL {
                try? FileManager.default.removeItem(at: fileURL)
            }
            index.removeValue(forKey: entry.key)
        }

        let obsoleteDownloads = imageDownloads.compactMap { venueID, download in
            expectedTokens[String(venueID)] == download.token ? nil : venueID
        }
        for venueID in obsoleteDownloads {
            imageDownloads[venueID]?.task.cancel()
            imageDownloads.removeValue(forKey: venueID)
        }

        if let files = try? FileManager.default.contentsOfDirectory(
            at: imageCacheDirectory,
            includingPropertiesForKeys: nil
        ) {
            let indexedNames = Set(index.keys.compactMap { Int($0) }.map {
                imageFileURL(venueID: $0).lastPathComponent
            })
            for file in files where file.lastPathComponent != imageIndexURL.lastPathComponent
                && !indexedNames.contains(file.lastPathComponent) {
                try? FileManager.default.removeItem(at: file)
            }
        }

        saveImageIndex(index)
    }

    private func isValidImageData(_ data: Data) -> Bool {
        data.starts(with: [0xFF, 0xD8, 0xFF]) // JPEG
            || data.starts(with: [0x89, 0x50, 0x4E, 0x47]) // PNG
            || data.starts(with: [0x47, 0x49, 0x46, 0x38]) // GIF
            || (data.count >= 12
                && data.starts(with: [0x52, 0x49, 0x46, 0x46])
                && data[8 ..< 12].elementsEqual([0x57, 0x45, 0x42, 0x50])) // WebP
    }
}
