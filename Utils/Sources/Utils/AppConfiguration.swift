import Foundation
import Combine
import Disk

// MARK: - Data Definitions

/// App configuration that is provided by DanXi backend to remotely control app's behavior.
///
/// This type include some static methods for loading and updating configurations, and some publishers
/// to propagate the update to views that depends on this change.
public struct AppConfiguration: Codable {
    /// A map provided by DanXi backend to indicate the start date of each semester ID.
//    public let semesterStartDate: [Int: Date]
    public let banners: [Banner]
    
    /// Initializer that creates an empty configuration
    init() {
//        semesterStartDate = [:]
        banners = []
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

// MARK: - Getters and Publishers
extension AppConfiguration {
    public static var shared = AppConfiguration()
    
    public static func initialFetch() {
        if let configuration = try? Disk.retrieve("configuration.json", from: .applicationSupport, as: AppConfiguration.self) {
            shared = configuration
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
        
        let configuration = try decoder.decode(AppConfiguration.self, from: data)
        saveConfiguration(configuration)
    }
    
    /// Set shared and publish changes
    static func saveConfiguration(_ configuration: AppConfiguration) {
//        if configuration.semesterStartDate != shared.semesterStartDate {
//            semesterMapPublisher.send(configuration.semesterStartDate)
//        }
        
        if configuration.banners != shared.banners {
            bannerPublisher.send(configuration.banners)
        }
        
        shared = configuration
        
        Task(priority: .background) {
            try Disk.save(configuration, to: .applicationSupport, as: "configuration.json")
        }
    }
    
    public static let semesterMapPublisher = PassthroughSubject<[Int: Date], Never>()
    public static let bannerPublisher = PassthroughSubject<[Banner], Never>()
}
