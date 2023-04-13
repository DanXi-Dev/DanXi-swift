import SwiftUI

class FDHomeModel: ObservableObject {
    @Published var path = NavigationPath()
    @AppStorage("campus-unpinned") var unpinned: [FDSection] = [.sport, .pay, .bus, .ecard, .score, .rank, .playground]
    
    func openURL(_ url: URL) {
        guard url.host == "campus" && url.pathComponents.count >= 2 else {
            return
        }
        
        if let section = FDSection(rawValue: url.pathComponents[1]) {
            path.removeLast(path.count)
            path.append(section)
        }
    }
}

enum FDSection: String, Codable {
    case sport, pay, bus, ecard, score, rank, playground
}
