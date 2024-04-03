import Foundation
import Combine
#if canImport(Disk)
import Disk
#endif

// MARK: - Configuration Center

public enum ConfigurationCenter {
    public static var configuration = AppConfiguration()
    
    public static let semesterMapPublisher = PassthroughSubject<[Int: Date], Never>()
    public static let bannerPublisher = PassthroughSubject<[Banner], Never>()
    
    public static func initialFetch() {
        if let configuration = try? Disk.retrieve("configuration.json", from: .applicationSupport, as: AppConfiguration.self) {
            self.configuration = configuration
        }
        
        Task(priority: .background) {
            try await refresh()
        }
    }
    
    public static func refresh() async throws {
        let url = URL(string: "https://danxi-static.fduhole.com/swift.json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        let configurationResponse = try decoder.decode(ConfigurationResponse.self, from: data)
        let configuration = configurationResponse.constructConfiguration()
        saveConfiguration(configuration)
    }
    
    private struct ConfigurationResponse: Codable {
        let semesterStartDate: [String: Date]
        let banners: [Banner]
        let userAgent: String
        
        func constructConfiguration() -> AppConfiguration {
            var convertedSemsterStartDate: [Int: Date] = [:]
            for (idString, date) in semesterStartDate {
                if let id = Int(idString) {
                    convertedSemsterStartDate[id] = date
                }
            }
            
            return AppConfiguration(semesterStartDate: convertedSemsterStartDate, banners: banners, userAgent: userAgent)
        }
    }
    
    /// Set shared and publish changes
    static func saveConfiguration(_ configuration: AppConfiguration) {
        if configuration.semesterStartDate != self.configuration.semesterStartDate {
            Task { @MainActor in
                semesterMapPublisher.send(configuration.semesterStartDate)
            }
        }
        
        if configuration.banners != self.configuration.banners {
            Task { @MainActor in
                bannerPublisher.send(configuration.banners)
            }
        }
        
        self.configuration = configuration
        
        Task(priority: .background) {
            try Disk.save(configuration, to: .applicationSupport, as: "configuration.json")
        }
    }
}

// MARK: - Data Definitions

/// App configuration that is provided by DanXi backend to remotely control app's behavior.
///
/// This type include some static methods for loading and updating configurations, and some publishers
/// to propagate the update to views that depends on this change.
public struct AppConfiguration: Codable {
    /// A map provided by DanXi backend to indicate the start date of each semester ID.
    public let semesterStartDate: [Int: Date]
    public let banners: [Banner]
    public let userAgent: String
    
    /// Initializer that creates an empty configuration
    init() {
        semesterStartDate = [:]
        banners = []
        userAgent = "DXSwift"
    }
    
    init(semesterStartDate: [Int: Date], banners: [Banner], userAgent: String) {
        self.semesterStartDate = semesterStartDate
        self.banners = banners
        self.userAgent = userAgent
    }
}

/// Banner that is displayed at the top of forum page.
public struct Banner: Codable, Equatable {
    public let title: String
    /// Action can be a floor ID (##123456), a hole ID (#12345), or a URL.
    public let action: String
    /// Text that should be displayed on the button.
    public let button: String
}
