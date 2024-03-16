import SwiftUI

class FDNavigator: ObservableObject {
    @Published var path = NavigationPath()
    @AppStorage("campus-pinned") var cards: [FDSection] = []
    @AppStorage("campus-unpinned") var pages: [FDSection] = []
    
    init() {
        // when the app update to include more sections, update storage
        if self.pages.count != FDSection.allCases.count {
            self.pages = FDSection.allCases
                .filter({ !cards.contains($0) })
        }
    }
    
    func pin(section: FDSection) {
        if pages.contains(section) && FDSection.pinnable.contains(section) {
            withAnimation {
                pages.removeAll { $0 == section }
                cards.append(section)
            }
        }
    }
    
    func unpin(section: FDSection) {
        if cards.contains(section) {
            withAnimation {
                cards.removeAll { $0 == section }
                pages.append(section)
            }
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
    case sport, pay, bus, ecard, score, rank, playground, courses, electricity, notice, library, canteen
    static let gradHidden: Set<FDSection> = [.sport, .rank, .score]
    static let staffHidden: Set<FDSection> = [.sport, .rank, .score, .electricity]
    static let pinnable: Set<FDSection> = [.ecard, .electricity, .notice]
}
