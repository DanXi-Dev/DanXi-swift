import SwiftUI
import Utils

class CampusNavigator: ObservableObject {    
    @Published var path = NavigationPath()
    @AppStorage("campus-pinned") var cards: [CampusSection] = []
    @AppStorage("campus-unpinned") var pages: [CampusSection] = []
    @AppStorage("campus-hidden") var hidden: [CampusSection] = []
    
    init() {
        // when the app update to include more sections, update storage
        for feature in CampusSection.allCases {
            if !cards.contains(feature) && !pages.contains(feature) && !hidden.contains(feature) {
                // A new feature has been added to the app
                if CampusSection.pinnable.contains(feature) {
                    cards.append(feature)
                } else {
                    pages.append(feature)
                }
            }
        }
    }
    
    func pin(section: CampusSection) {
        if pages.contains(section) && CampusSection.pinnable.contains(section) {
            withAnimation {
                pages.removeAll { $0 == section }
                cards.append(section)
            }
        }
    }
    
    func unpin(section: CampusSection) {
        if cards.contains(section) {
            withAnimation {
                cards.removeAll { $0 == section }
                pages.append(section)
            }
        }
    }
    
    func remove(section: CampusSection) {
        if pages.contains(section) {
            withAnimation {
                pages.removeAll { $0 == section }
                hidden.append(section)
            }
        }
    }
    
    func unhide(section: CampusSection) {
        if hidden.contains(section) {
            withAnimation {
                hidden.removeAll { $0 == section }
                pages.append(section)
            }
        }
    }
    
    func openURL(_ url: URL) {
        guard url.host == "campus" && url.pathComponents.count >= 2 else {
            return
        }
        
        if let section = CampusSection(rawValue: url.pathComponents[1]) {
            path.removeLast(path.count)
            path.append(section)
        }
    }
}

