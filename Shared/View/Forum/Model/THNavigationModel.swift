import SwiftUI

@MainActor
class THNavigationModel: ObservableObject {
    @Published var path = NavigationPath()
    @Published var page = THPage.browse
    
    func openURL(_ url: URL) {
        guard url.host == "forum" && url.pathComponents.count >= 2 else {
            return
        }
        let base = url.pathComponents[1]
        
        if url.pathComponents.count == 2 {
            switch base {
            case "browse":
                page = .browse
            case "favorite":
                page = .favorite
            case "my-post":
                page = .mypost
            case "tags":
                page = .tags
            case "notifications":
                page = .notifications
            case "report":
                page = .report
            default: break
            }
        } else {
            let detail = url.pathComponents[2]
            
            switch base {
            case "floor":
                if let floorId = Int(detail) {
                    path.append(THHoleLoader(floorId: floorId))
                }
            case "hole":
                if let holeId = Int(detail) {
                    path.append(THHoleLoader(holeId: holeId))
                }
            default: break
            }
        }
    }
}

enum THPage {
    case browse
    case favorite
    case mypost
    case tags
    case notifications
    case report
}
