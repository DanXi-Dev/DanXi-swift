import SwiftUI

class FDHomeModel: ObservableObject {
    @Published var path = NavigationPath()
    @AppStorage("campus-unpinned") var pages: [FDSection] = []
    
    init() {
        if self.pages.count != FDSection.allCases.count {
            self.pages = FDSection.allCases
        }
    }
    
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

enum FDSection: String, Codable, CaseIterable {
    case sport, pay, bus, ecard, score, rank, playground, courses, electricity, notice
}
