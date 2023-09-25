import SwiftUI

@MainActor
class THNavigator: ObservableObject {
    @Published var path = NavigationPath()
    
    func openURL(_ url: URL) {
        guard url.host == "forum" && url.pathComponents.count >= 2 else {
            return
        }
        let base = url.pathComponents[1]
        
        if url.pathComponents.count == 2 {
            switch base {
            case "favorite":
                setSection(.favorite)
            case "subscription":
                setSection(.subscription)
            case "my-post":
                setSection(.mypost)
            case "tags":
                setSection(.tags)
            case "notifications":
                setSection(.notifications)
            case "report":
                setSection(.report)
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
    
    func setSection(_ page: THPage) {
        path.removeLast(path.count)
        path.append(page)
    }
}

enum THPage {
    case favorite
    case subscription
    case mypost
    case tags
    case notifications
    case report
    case history
}
