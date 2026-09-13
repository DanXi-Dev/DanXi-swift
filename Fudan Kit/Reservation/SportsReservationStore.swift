import Foundation

/// State boundary for the rebuilt sports reservation feature.
public actor SportsReservationStore: ClearableStorage {
    public static let shared = SportsReservationStore()

    private struct VenueLoad {
        let id: UUID
        let task: Task<[BookingVenue], Error>
    }

    private struct ImageDownload {
        let id: UUID
        let token: String
        let task: Task<Data, Error>
    }

    private var cachedVenues: [BookingVenue]?
    private var venueLoad: VenueLoad?
    private var completedVenueLoadID: UUID?
    private var imageIndex: [String: String]?
    private var imageDownloads: [Int: ImageDownload] = [:]
    private var latestImageRequests: [Int: (id: UUID, token: String)] = [:]

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

        let load: VenueLoad
        if let venueLoad {
            load = venueLoad
        } else {
            let id = UUID()
            let task = Task { try await Self.fetchAllVenues() }
            load = VenueLoad(id: id, task: task)
            venueLoad = load
        }

        do {
            let venues = try await load.task.value
            if venueLoad?.id == load.id {
                reconcileImageCache(with: venues)
                cachedVenues = venues
                venueLoad = nil
                completedVenueLoadID = load.id
                return venues
            }

            // Another caller may already have committed this shared task's result.
            if completedVenueLoadID == load.id, let cachedVenues {
                return cachedVenues
            }
            throw CancellationError()
        } catch {
            if venueLoad?.id == load.id {
                venueLoad = nil
            }
            throw error
        }
    }

    private static func fetchAllVenues() async throws -> [BookingVenue] {
        let pageSize = 100
        var page = 1
        var receivedCount = 0
        var total = Int.max
        var venueOrder: [Int] = []
        var venuesByID: [Int: BookingVenue] = [:]

        while receivedCount < total {
            let response = try await SportsReservationAPI.getVenues(page: page, pageSize: pageSize)
            receivedCount += response.venues.count
            total = max(0, response.total)

            for venue in response.venues {
                if venuesByID.updateValue(venue, forKey: venue.id) == nil {
                    venueOrder.append(venue.id)
                }
            }

            guard !response.venues.isEmpty else {
                break
            }
            page += 1
        }

        // The upstream list may repeat an item within a page or across page boundaries.
        // Keep its first position while using the most recently received representation.
        return venueOrder.compactMap { venuesByID[$0] }
    }

    public func getVenueImage(_ venue: BookingVenue) async throws -> Data? {
        guard !venue.images.isEmpty else { return nil }
        if let cachedVenues,
           !cachedVenues.contains(where: { $0.id == venue.id && $0.images == venue.images }) {
            return nil
        }

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
        let download: ImageDownload
        if let currentDownload = imageDownloads[venue.id], currentDownload.token == token {
            download = currentDownload
        } else {
            imageDownloads[venue.id]?.task.cancel()
            let id = UUID()
            let task = Task {
                try await SportsReservationAPI.getVenueImage(token: token)
            }
            download = ImageDownload(id: id, token: token, task: task)
            imageDownloads[venue.id] = download
            latestImageRequests[venue.id] = (id, token)
        }

        let data: Data
        do {
            data = try await download.task.value
        } catch {
            if imageDownloads[venue.id]?.id == download.id {
                imageDownloads.removeValue(forKey: venue.id)
            }
            throw error
        }
        if imageDownloads[venue.id]?.id == download.id {
            imageDownloads.removeValue(forKey: venue.id)
        }

        // Do not restore an image invalidated by a refresh, clear, or newer request.
        guard latestImageRequests[venue.id]?.id == download.id,
              latestImageRequests[venue.id]?.token == token else {
            return nil
        }
        if let cachedVenues,
           !cachedVenues.contains(where: { $0.id == venue.id && $0.images == token }) {
            return nil
        }
        guard isValidImageData(data) else {
            throw CampusError.customError(message: "场馆图片返回了无效数据")
        }

        do {
            try FileManager.default.createDirectory(
                at: imageCacheDirectory,
                withIntermediateDirectories: true
            )
            try data.write(to: fileURL, options: .atomic)
            index = loadImageIndex()
            index[key] = token
            saveImageIndex(index)
        } catch {
            // Disk caching is best-effort; a valid downloaded image is still usable.
        }
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
        venueLoad?.task.cancel()
        venueLoad = nil
        completedVenueLoadID = nil
        imageIndex = nil
        imageDownloads.values.forEach { $0.task.cancel() }
        imageDownloads.removeAll()
        latestImageRequests.removeAll()
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
        imageIndex = index
        do {
            try FileManager.default.createDirectory(
                at: imageCacheDirectory,
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(index)
            try data.write(to: imageIndexURL, options: .atomic)
        } catch {
            // Image caching is best-effort and must not prevent venue loading.
        }
    }

    private func reconcileImageCache(with venues: [BookingVenue]) {
        var index = loadImageIndex()
        var expectedTokens: [String: String] = [:]
        for venue in venues where !venue.images.isEmpty {
            expectedTokens[String(venue.id)] = venue.images
        }

        let invalidEntries = index.compactMap { key, token -> (key: String, fileURL: URL?)? in
            guard let venueID = Int(key), key == String(venueID) else {
                return (key: key, fileURL: nil)
            }
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

        let obsoleteRequests = latestImageRequests.compactMap { venueID, request in
            expectedTokens[String(venueID)] == request.token ? nil : venueID
        }
        for venueID in obsoleteRequests {
            imageDownloads[venueID]?.task.cancel()
            imageDownloads.removeValue(forKey: venueID)
            latestImageRequests.removeValue(forKey: venueID)
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
